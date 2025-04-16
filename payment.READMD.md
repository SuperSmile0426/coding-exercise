# Payment Flow Design: Monthly Subscriptions

## Overview
High-Level Payment Flow (User Journey)

## Core Components
1. **Frontend (Mobile/iOS App)**
   - Plan selection interface
   - Payment integration
   - Access control

2. **Backend (Supabase/API)**
   - Session management
   - Webhook handling
   - Database operations

3. **Payment Processor (Stripe)**
   - Payment processing
   - Subscription management
   - Webhook notifications

## Payment Flow Steps

### 1. Plan Selection
- User selects subscription plan (Basic/Premium)
- User initiates subscription process

### 2. Payment Session Creation
- Frontend calls secure backend endpoint with plan ID
- Backend creates Stripe checkout session/payment intent
- Supports multiple payment methods:
  - Credit cards
  - Apple Pay
  - Google Pay
- Returns Stripe Checkout URL or client secret

### 3. Payment Processing
- User completes payment via:
  - Stripe Checkout page (web)
  - In-app payment sheet (mobile)
- Payment methods available based on platform:
  - Web: Credit cards, Apple Pay, Google Pay
  - Mobile: Native payment sheets with wallet options

### 4. Subscription Activation
- Stripe processes payment
- Creates customer subscription
- Charges first billing cycle
- Sends webhook notification to backend

### 5. Database Synchronization
- Backend receives Stripe webhook
- Verifies webhook signature
- Updates Supabase database with:
  - Subscription status
  - Plan details
  - Billing information
  - Next billing date

### 6. Access Management
- Database reflects active subscription
- Frontend checks subscription status
- Premium features unlocked
- Failed payments handled appropriately

### 7. Security Considerations
- Secure backend endpoints
- Webhook signature verification
- No sensitive data stored in frontend
- Real-time database synchronization

### 8. Error Handling
- Payment failure scenarios
- Subscription status checks
- Retry mechanisms
- User notifications





## Payment Provider Integration Strategy

### 1. Stripe as Core Billing System
- Primary payment platform for web applications
- Features:
  - Recurring subscription support
  - Customer management
  - Multiple payment method support
- Integration options:
  - Stripe Checkout (hosted payment page)
  - Stripe Elements (custom UI)
- Benefits:
  - PCI compliance handled
  - Robust subscription management
  - Webhook support for lifecycle events
  - Future extensibility (ACH, PayPal via Stripe)

### 2. Apple Pay Integration
- Platform support:
  - Web (Safari)
  - Native iOS apps
- Implementation:
  - Web: Stripe Checkout/Payment Request Button
  - iOS: Stripe iOS SDK
- Security:
  - Token-based payments
  - No card data exposure
- App Store considerations:
  - Digital content guidelines compliance
  - Professional education service classification

### 3. Google Pay Integration
- Platform support:
  - Web (Chrome/Android)
  - Native Android apps
- Implementation:
  - Web: Stripe Payment Request API
  - Android: Stripe Android SDK/Google Pay APIs
- Features:
  - Tokenized card support
  - Recurring billing compatibility
  - Seamless integration with Stripe

### 4. Future Payment Methods
- Modular architecture design
- Potential additions:
  - Local payment methods (ACH, SEPA)
  - Alternative providers (PayPal)
- Implementation strategy:
  - Isolated provider-specific logic
  - Unified database storage
  - Provider field in subscription records
- Initial focus on Stripe platform
- Maintain flexibility for future expansion




## Database Schema for Subscription Management

### 1. User & Customer Mapping
- Table: `customers`
- Fields:
  - `user_id` (UUID, primary key)
  - `stripe_customer_id` (string)
- Security:
  - No RLS policy (backend only)
  - Created during first checkout
- Purpose:
  - Links Supabase users to Stripe customers
  - Enables subscription management
  - Supports webhook event handling

### 2. Plans & Pricing
- Tables:
  - `products`
  - `prices`
- Fields:
  - `id` (Stripe price ID)
  - `product_name` (e.g., "Basic")
  - `unit_amount` (e.g., 1000 for $10.00)
  - `interval` (e.g., "month")
  - `active` (boolean)
- Features:
  - Dynamic plan management
  - Webhook synchronization
  - Read-only client access
- Benefits:
  - Flexible pricing changes
  - Consistent plan display
  - Easy plan additions

### 3. Subscriptions
- Table: `subscriptions`
- Fields:
  - `id` (Stripe Subscription ID)
  - `user_id` (UUID)
  - `price_id` (plan reference)
  - `status` (enum: trialing, active, past_due, etc.)
  - `start_date` (timestamp)
  - `current_period_end` (timestamp)
  - `cancel_at` (timestamp)
  - `canceled_at` (timestamp)
  - `trial_end` (timestamp)
  - `cancel_at_period_end` (boolean)
- Security:
  - RLS for user-specific access
  - Backend-only updates
- Features:
  - Single active subscription per user
  - Historical record keeping
  - Status tracking
  - Billing cycle management

### 4. Data Relationships
- Views:
  - `user_subscriptions_view`
- Features:
  - User subscription status
  - Current plan details
  - Simplified queries
- Security:
  - No sensitive payment data
  - Identifier-only storage
  - Compliance-friendly


## Subscription Lifecycle Events

### 1. New Subscription Creation
- Trigger: `checkout.session.completed` and `customer.subscription.created`
- Flow:
  - Verify webhook signature
  - Extract session/subscription details
  - Create/update subscription record
- Database Updates:
  - Insert new subscription row
  - Set status to "active" or "trialing"
  - Link Stripe customer ID if new
- Features:
  - Idempotent processing
  - Duplicate event handling
  - Full subscription object storage

### 2. Payment Processing
#### Success (Renewal)
- Trigger: `invoice.paid`
- Actions:
  - Update subscription status
  - Set new period end date
  - Send confirmation email
- Features:
  - Automatic renewal handling
  - Access provisioning
  - Receipt generation

#### Failure (Renewal)
- Trigger: `invoice.payment_failed`
- Actions:
  - Update status to "past_due"
  - Enable grace period
  - Notify user
- Features:
  - Smart retry system
  - Grace period management
  - User notifications

### 3. Subscription Cancellation
#### User-Initiated
- Triggers:
  - `customer.subscription.updated`
  - `customer.subscription.deleted`
- Flow:
  - Set `cancel_at_period_end`
  - Update subscription status
  - Handle end of period
- Features:
  - End-of-period access
  - Status tracking
  - User notifications

#### Stripe Portal
- Features:
  - Self-service management
  - Payment method updates
  - Subscription changes
- Integration:
  - Webhook event handling
  - Status synchronization
  - Access management

### 4. Plan Changes & Updates
- Trigger: `customer.subscription.updated`
- Changes Handled:
  - Plan upgrades/downgrades
  - Payment method updates
  - Billing cycle changes
- Features:
  - Proration handling
  - Status updates
  - Access level changes

### 5. Trial Period Management
- Events:
  - `customer.subscription.trial_will_end`
  - Trial end transitions
- Features:
  - Trial status tracking
  - End-of-trial notifications
  - Payment collection
- Flow:
  - Trial period monitoring
  - Automatic conversion
  - Payment processing

### 6. Webhook Implementation
- Security:
  - Signature verification
  - Endpoint protection
  - Event filtering
- Features:
  - Idempotent processing
  - Event logging
  - Error handling
- Event Types:
  - Product/price updates
  - Subscription events
  - Payment events

### 7. Recovery & Retry System
- Features:
  - Automatic retries
  - Payment method updates
  - User notifications
- Flow:
  - Grace period management
  - Retry scheduling
  - Final cancellation handling
- User Actions:
  - Payment method updates
  - Subscription reactivation
  - Access restoration

### 8. Edge Cases & Monitoring
- Features:
  - State reconciliation
  - Error recovery
  - System monitoring
- Handling:
  - Missed webhooks
  - Service downtime
  - Duplicate subscriptions
- Maintenance:
  - Periodic sync checks
  - Status verification
  - Error logging



## Access Control Implementation

### 1. Database Security (RLS)
#### Premium Content Protection
- Policy Example:
```sql
create policy "Allow access to premium content for subscribed users" 
  on premium_content_table 
  for select using (
    exists (
      select 1 from subscriptions 
      where subscriptions.user_id = auth.uid() 
        and subscriptions.status in ('active','trialing')
    )
  );
```
- Features:
  - Row-level security
  - Status-based access
  - Real-time enforcement
- Protected Resources:
  - Premium content tables
  - User data tables
  - Subscription records

#### Subscription Data Protection
- Policies:
  - User-specific access
  - Internal table protection
  - Status verification
- Security Measures:
  - JWT verification
  - Role-based access
  - Data isolation

### 2. Application-Level Security
#### API Protection
- Features:
  - Route protection
  - Status verification
  - Error handling
- Implementation:
  - Middleware checks
  - JWT validation
  - Service role usage

#### Edge Function Security
- Features:
  - JWT decoding
  - Role verification
  - Error handling
- Implementation:
  - Auth header processing
  - Service role access
  - Status verification

### 3. Client-Side Implementation
#### UI/UX Controls
- Features:
  - Feature visibility
  - Upgrade prompts
  - Status display
- Implementation:
  - Status queries
  - Real-time updates
  - User feedback

#### Status Management
- Features:
  - Session handling
  - Status caching
  - Real-time sync
- Implementation:
  - Login checks
  - Periodic updates
  - Error handling

### 4. Tier-Based Access Control
#### Plan Differentiation
- Features:
  - Basic vs Premium
  - Feature mapping
  - Access levels
- Implementation:
  - Price ID mapping
  - Plan level checks
  - Feature gates

#### Role Management
- Features:
  - Custom claims
  - JWT enhancement
  - Role verification
- Implementation:
  - Token updates
  - Role mapping
  - Access control

### 5. Free Tier & Grace Periods
#### Free User Access
- Features:
  - Basic functionality
  - Limited features
  - Upgrade prompts
- Implementation:
  - Access checks
  - Feature gates
  - User guidance

#### Grace Period Handling
- Features:
  - Period extension
  - Status tracking
  - Access management
- Implementation:
  - Status checks
  - Period validation
  - Access control

### 6. Usage Limits
#### Basic Plan Limits
- Features:
  - Usage tracking
  - Limit enforcement
  - User notifications
- Implementation:
  - Counter management
  - Policy enforcement
  - Error handling

#### Premium Plan Features
- Features:
  - Unlimited access
  - Advanced features
  - Priority support
- Implementation:
  - Feature gates
  - Access control
  - Status verification

### 7. Security Best Practices
#### Data Protection
- Features:
  - Encryption
  - Access control
  - Audit logging
- Implementation:
  - Secure storage
  - Access policies
  - Monitoring

#### Error Handling
- Features:
  - Graceful degradation
  - User notifications
  - System logging
- Implementation:
  - Error catching
  - Status updates
  - User feedback



## Modularity, Security, and Future Extensibility

### Modularity
- **Payment Processing** 
  - Handled by Stripe via dedicated module/endpoint and webhooks
  - Clean separation of payment concerns from core application logic
  - Provider-agnostic design allows for easy integration of additional payment providers

### Security
- **PCI Compliance** 
  - All credit card handling offloaded to Stripe
  - No raw card data handling
  - SSL and Stripe libraries implementation

- **Authentication & Authorization** 
  - Supabase Auth for user identification (secure JWTs)
  - RLS policies for data access control
  - Backend validation of user actions

- **Data Protection** 
  - Secure storage of API keys and secrets
  - Webhook security verification
  - No direct client-side subscription editing

### System Components 

### Database Structure
- **Subscriptions Table** 
  - User ID mapping
  - Provider-specific identifiers
  - Subscription status tracking
  - Metadata storage capability

### API Endpoints
- **Protected Routes** 
  - Subscription creation
  - Status checking
  - Cancellation handling
  - Plan validation

### Webhook Handlers
- **Event Processing** 
  - Secure event verification
  - Database updates
  - Status synchronization

### Future Extensibility 
- JWT enrichment with plan-level claims
- Supabase Realtime subscription tracking
- Stripe Customer Portal integration
- Admin UI for support/debugging
- Automated sync job for Stripe-DB state verification
