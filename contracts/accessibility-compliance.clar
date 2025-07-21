;; Accessibility Compliance Contract
;; Ensures wheelchair-accessible table availability

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-INVALID-TABLE (err u401))
(define-constant ERR-COMPLIANCE-VIOLATION (err u402))
(define-constant ERR-INSUFFICIENT-ACCESSIBLE-TABLES (err u403))
(define-constant ERR-REQUEST-NOT-FOUND (err u404))

;; Data Variables
(define-data-var next-request-id uint u1)
(define-data-var min-accessible-percentage uint u25) ;; 25% minimum accessible tables
(define-data-var total-tables uint u0)
(define-data-var accessible-tables uint u0)

;; Data Maps
(define-map accessibility-features
  { table-id: uint }
  {
    is-wheelchair-accessible: bool,
    has-extended-surface: bool,
    has-accessible-seating: bool,
    path-width: uint, ;; in inches
    surface-height: uint, ;; in inches
    compliance-level: (string-ascii 20)
  }
)

(define-map accommodation-requests
  { request-id: uint }
  {
    user: principal,
    table-id: uint,
    accommodation-type: (string-ascii 50),
    description: (string-ascii 200),
    requested-date: uint,
    status: (string-ascii 20),
    assigned-table: (optional uint)
  }
)

(define-map compliance-inspections
  { table-id: uint, inspection-date: uint }
  {
    inspector: principal,
    ada-compliant: bool,
    violations: (list 10 (string-ascii 100)),
    remediation-required: bool,
    next-inspection-due: uint
  }
)

(define-map accessibility-modifications
  { table-id: uint }
  {
    modification-history: (list 20 (string-ascii 100)),
    total-cost: uint,
    last-modified: uint
  }
)

(define-map user-accessibility-profiles
  { user: principal }
  {
    mobility-needs: (string-ascii 100),
    preferred-features: (list 5 (string-ascii 50)),
    accommodation-history: (list 50 uint)
  }
)

;; Public Functions

;; Register accessibility features for a table
(define-public (register-table-accessibility (table-id uint) (is-wheelchair-accessible bool) (has-extended-surface bool) (has-accessible-seating bool) (path-width uint) (surface-height uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> table-id u0) ERR-INVALID-TABLE)

    (let (
      (compliance-level (determine-compliance-level is-wheelchair-accessible path-width surface-height))
    )
      (map-set accessibility-features
        { table-id: table-id }
        {
          is-wheelchair-accessible: is-wheelchair-accessible,
          has-extended-surface: has-extended-surface,
          has-accessible-seating: has-accessible-seating,
          path-width: path-width,
          surface-height: surface-height,
          compliance-level: compliance-level
        }
      )

      ;; Update accessible table count
      (if is-wheelchair-accessible
        (var-set accessible-tables (+ (var-get accessible-tables) u1))
        true
      )

      (var-set total-tables (+ (var-get total-tables) u1))

      ;; Check overall compliance
      (check-overall-compliance)

      (ok true)
    )
  )
)

;; Request special accommodation
(define-public (request-accommodation (table-id uint) (accommodation-type (string-ascii 50)) (description (string-ascii 200)) (requested-date uint))
  (let (
    (request-id (var-get next-request-id))
  )
    (asserts! (> table-id u0) ERR-INVALID-TABLE)
    (asserts! (> requested-date block-height) (err u405))

    (map-set accommodation-requests
      { request-id: request-id }
      {
        user: tx-sender,
        table-id: table-id,
        accommodation-type: accommodation-type,
        description: description,
        requested-date: requested-date,
        status: "pending",
        assigned-table: none
      }
    )

    ;; Update user profile
    (update-user-accessibility-profile tx-sender request-id)

    ;; Increment request ID
    (var-set next-request-id (+ request-id u1))

    (ok request-id)
  )
)

;; Approve accommodation request
(define-public (approve-accommodation (request-id uint) (assigned-table-id uint))
  (let (
    (request (unwrap! (map-get? accommodation-requests { request-id: request-id }) ERR-REQUEST-NOT-FOUND))
    (table-features (unwrap! (map-get? accessibility-features { table-id: assigned-table-id }) ERR-INVALID-TABLE))
  )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status request) "pending") (err u406))
    (asserts! (get is-wheelchair-accessible table-features) ERR-COMPLIANCE-VIOLATION)

    (map-set accommodation-requests
      { request-id: request-id }
      (merge request {
        status: "approved",
        assigned-table: (some assigned-table-id)
      })
    )

    (ok true)
  )
)

;; Conduct compliance inspection
(define-public (conduct-inspection (table-id uint) (inspector principal) (ada-compliant bool) (violations (list 10 (string-ascii 100))))
  (let (
    (inspection-date block-height)
    (next-inspection (+ block-height u2628000)) ;; ~1 month later
  )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> table-id u0) ERR-INVALID-TABLE)

    (map-set compliance-inspections
      { table-id: table-id, inspection-date: inspection-date }
      {
        inspector: inspector,
        ada-compliant: ada-compliant,
        violations: violations,
        remediation-required: (not ada-compliant),
        next-inspection-due: next-inspection
      }
    )

    ;; If not compliant, update table accessibility status
    (if (not ada-compliant)
      (update-table-compliance-status table-id false)
      true
    )

    (ok true)
  )
)

;; Add accessibility modification
(define-public (add-accessibility-modification (table-id uint) (modification-description (string-ascii 100)) (cost uint))
  (let (
    (current-modifications (default-to {
      modification-history: (list),
      total-cost: u0,
      last-modified: u0
    } (map-get? accessibility-modifications { table-id: table-id })))
    (updated-history (unwrap-panic (as-max-len? (append (get modification-history current-modifications) modification-description) u20)))
  )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> table-id u0) ERR-INVALID-TABLE)

    (map-set accessibility-modifications
      { table-id: table-id }
      {
        modification-history: updated-history,
        total-cost: (+ (get total-cost current-modifications) cost),
        last-modified: block-height
      }
    )

    (ok true)
  )
)

;; Get table accessibility features
(define-read-only (get-accessibility-features (table-id uint))
  (map-get? accessibility-features { table-id: table-id })
)

;; Get accommodation request
(define-read-only (get-accommodation-request (request-id uint))
  (map-get? accommodation-requests { request-id: request-id })
)

;; Get compliance inspection results
(define-read-only (get-inspection-results (table-id uint) (inspection-date uint))
  (map-get? compliance-inspections { table-id: table-id, inspection-date: inspection-date })
)

;; Check if table is ADA compliant
(define-read-only (is-ada-compliant (table-id uint))
  (match (map-get? accessibility-features { table-id: table-id })
    features (and
      (get is-wheelchair-accessible features)
      (>= (get path-width features) u36) ;; 36 inches minimum
      (<= (get surface-height features) u34) ;; 34 inches maximum
    )
    false
  )
)

;; Get accessibility compliance percentage
(define-read-only (get-compliance-percentage)
  (let (
    (total (var-get total-tables))
    (accessible (var-get accessible-tables))
  )
    (if (> total u0)
      (/ (* accessible u100) total)
      u0
    )
  )
)

;; Get user accessibility profile
(define-read-only (get-user-accessibility-profile (user principal))
  (map-get? user-accessibility-profiles { user: user })
)

;; Private Functions

;; Determine compliance level based on features
(define-private (determine-compliance-level (is-accessible bool) (path-width uint) (surface-height uint))
  (if (and is-accessible (>= path-width u36) (<= surface-height u34))
    "full-ada-compliant"
    (if is-accessible
      "partially-accessible"
      "not-accessible"
    )
  )
)

;; Check overall park compliance
(define-private (check-overall-compliance)
  (let (
    (compliance-percentage (get-compliance-percentage))
    (min-required (var-get min-accessible-percentage))
  )
    (< compliance-percentage min-required)
  )
)

;; Update table compliance status
(define-private (update-table-compliance-status (table-id uint) (is-compliant bool))
  (let (
    (current-features (unwrap-panic (map-get? accessibility-features { table-id: table-id })))
  )
    (map-set accessibility-features
      { table-id: table-id }
      (merge current-features {
        is-wheelchair-accessible: is-compliant,
        compliance-level: (if is-compliant "full-ada-compliant" "not-accessible")
      })
    )
  )
)

;; Update user accessibility profile
(define-private (update-user-accessibility-profile (user principal) (request-id uint))
  (let (
    (current-profile (default-to {
      mobility-needs: "",
      preferred-features: (list),
      accommodation-history: (list)
    } (map-get? user-accessibility-profiles { user: user })))
    (updated-history (unwrap-panic (as-max-len? (append (get accommodation-history current-profile) request-id) u50)))
  )
    (map-set user-accessibility-profiles
      { user: user }
      (merge current-profile { accommodation-history: updated-history })
    )
  )
)

;; Admin function to update minimum accessibility percentage
(define-public (update-min-accessibility-percentage (new-percentage uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-percentage u100) (err u407))
    (var-set min-accessible-percentage new-percentage)
    (ok true)
  )
)
