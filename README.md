# Decentralized Public Park Picnic Table Reservation System

A blockchain-based system for managing picnic table reservations, maintenance, and accessibility in public parks using Clarity smart contracts.

## System Overview

This system consists of five interconnected smart contracts that manage different aspects of picnic table operations:

### 1. Booking Management Contract (`booking-management.clar`)
- Handles picnic table reservations for families and individuals
- Manages reservation slots, pricing, and availability
- Tracks user booking history and preferences
- Implements cancellation and refund policies

### 2. Maintenance Scheduling Contract (`maintenance-scheduling.clar`)
- Coordinates table cleaning and repair schedules
- Manages maintenance worker assignments
- Tracks maintenance history and costs
- Schedules preventive maintenance based on usage patterns

### 3. Damage Assessment Contract (`damage-assessment.clar`)
- Evaluates table condition through reporting system
- Manages damage severity ratings and repair priorities
- Tracks replacement needs and costs
- Handles damage deposits and claims

### 4. Accessibility Compliance Contract (`accessibility-compliance.clar`)
- Ensures wheelchair-accessible table availability
- Manages ADA compliance requirements
- Tracks accessibility features and modifications
- Handles special accommodation requests

### 5. Event Coordination Contract (`event-coordination.clar`)
- Manages large group reservations and corporate events
- Coordinates setup requirements and equipment needs
- Handles bulk booking discounts and group policies
- Manages event-specific accessibility requirements

## Key Features

- **Decentralized Governance**: Community-driven decision making for park policies
- **Transparent Pricing**: On-chain pricing with dynamic adjustments based on demand
- **Maintenance Tracking**: Complete audit trail of all maintenance activities
- **Accessibility Focus**: Dedicated systems ensuring equal access for all users
- **Damage Prevention**: Incentive systems to encourage proper table care
- **Event Support**: Specialized handling for large gatherings and celebrations

## Technical Architecture

### Data Structures
- **Tables**: Unique identifiers, location coordinates, capacity, accessibility features
- **Reservations**: Time slots, user information, payment status, special requirements
- **Maintenance Records**: Work orders, completion status, costs, worker assignments
- **Damage Reports**: Severity levels, repair estimates, responsible parties
- **Events**: Group size, setup requirements, coordination needs

### Security Features
- Multi-signature requirements for high-value operations
- Time-locked functions for maintenance scheduling
- Deposit systems for damage prevention
- Access control for administrative functions

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Basic understanding of Clarity smart contracts

### Installation
1. Clone the repository
2. Install dependencies: `npm install`
3. Run tests: `npm test`
4. Deploy contracts: `clarinet deploy`

### Usage Examples

#### Making a Reservation
```clarity
(contract-call? .booking-management reserve-table u1 u1640995200 u1640998800 u50)
