# Mollie Payment Integration - Backend Instructions

## Overview
The iOS app needs two endpoints to handle Mollie payments for ride bookings.

## Required Endpoints

### 1. Create Payment

**POST** `/.netlify/functions/mollie-create-payment`

**Purpose:** Create a Mollie payment and return checkout URL

**Headers:**
```
Authorization: Bearer {session_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "amount": 5000,
  "description": "Trip from Zurich HB to Airport",
  "redirectUrl": "veramo://payment-return",
  "webhookUrl": null,
  "metadata": {
    "pickup": "Zurich HB",
    "destination": "Zurich Airport",
    "date": "Dec 10, 2025",
    "vehicle": "Business"
  }
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "payment_id": "tr_WDqYK6vllg",
  "checkout_url": "https://www.mollie.com/checkout/..."
}
```

**Response (Error - 401/500):**
```json
{
  "success": false,
  "error": "Error message here"
}
```

**Implementation Steps:**

1. **Install Mollie SDK:**
```bash
# Node.js
npm install @mollie/api-client

# PHP
composer require mollie/mollie-api-php
```

2. **Create Payment:**

**Node.js Example:**
```javascript
const { createMollieClient } = require('@mollie/api-client');

exports.handler = async (event) => {
    // Validate session token
    const user = await validateSession(event.headers.authorization);
    if (!user) {
        return {
            statusCode: 401,
            body: JSON.stringify({ success: false, error: 'Unauthorized' })
        };
    }
    
    const { amount, description, redirectUrl, metadata } = JSON.parse(event.body);
    
    // Initialize Mollie client
    const mollieClient = createMollieClient({
        apiKey: process.env.MOLLIE_API_KEY
    });
    
    try {
        // Create payment
        const payment = await mollieClient.payments.create({
            amount: {
                currency: 'EUR',
                value: (amount / 100).toFixed(2) // Convert cents to EUR
            },
            description: description,
            redirectUrl: redirectUrl,
            webhookUrl: `${process.env.API_BASE_URL}/.netlify/functions/mollie-webhook`,
            metadata: {
                ...metadata,
                customerId: user.id
            }
        });
        
        return {
            statusCode: 200,
            body: JSON.stringify({
                success: true,
                payment_id: payment.id,
                checkout_url: payment._links.checkout.href
            })
        };
    } catch (error) {
        return {
            statusCode: 500,
            body: JSON.stringify({
                success: false,
                error: error.message
            })
        };
    }
};
```

**PHP Example:**
```php
use Mollie\Api\MollieApiClient;

$mollie = new MollieApiClient();
$mollie->setApiKey(getenv('MOLLIE_API_KEY'));

// Validate session token
$user = validateSession($_SERVER['HTTP_AUTHORIZATION']);
if (!$user) {
    http_response_code(401);
    echo json_encode(['success' => false, 'error' => 'Unauthorized']);
    exit;
}

$data = json_decode(file_get_contents('php://input'), true);

try {
    $payment = $mollie->payments->create([
        'amount' => [
            'currency' => 'EUR',
            'value' => number_format($data['amount'] / 100, 2, '.', '')
        ],
        'description' => $data['description'],
        'redirectUrl' => $data['redirectUrl'],
        'webhookUrl' => getenv('API_BASE_URL') . '/.netlify/functions/mollie-webhook',
        'metadata' => array_merge($data['metadata'], [
            'customerId' => $user->id
        ])
    ]);
    
    echo json_encode([
        'success' => true,
        'payment_id' => $payment->id,
        'checkout_url' => $payment->getCheckoutUrl()
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
```

### 2. Check Payment Status

**GET** `/.netlify/functions/mollie-payment-status?payment_id={payment_id}`

**Purpose:** Check if payment was completed

**Headers:**
```
Authorization: Bearer {session_token}
```

**Response (Success - 200):**
```json
{
  "status": "paid",
  "payment_id": "tr_WDqYK6vllg"
}
```

**Possible status values:**
- `open` - Payment created but not started
- `pending` - Payment started but not completed
- `paid` - Payment successful ✅
- `failed` - Payment failed
- `canceled` - Payment cancelled by user
- `expired` - Payment expired

**Implementation:**

**Node.js:**
```javascript
exports.handler = async (event) => {
    const user = await validateSession(event.headers.authorization);
    if (!user) {
        return { statusCode: 401, body: JSON.stringify({ error: 'Unauthorized' }) };
    }
    
    const paymentId = event.queryStringParameters.payment_id;
    
    const mollieClient = createMollieClient({
        apiKey: process.env.MOLLIE_API_KEY
    });
    
    try {
        const payment = await mollieClient.payments.get(paymentId);
        
        return {
            statusCode: 200,
            body: JSON.stringify({
                status: payment.status,
                payment_id: payment.id
            })
        };
    } catch (error) {
        return {
            statusCode: 500,
            body: JSON.stringify({ error: error.message })
        };
    }
};
```

### 3. Webhook (Optional but Recommended)

**POST** `/.netlify/functions/mollie-webhook`

**Purpose:** Receive payment status updates from Mollie

**Request Body:**
```
id=tr_WDqYK6vllg
```

**Implementation:**
```javascript
exports.handler = async (event) => {
    const paymentId = event.body.split('=')[1];
    
    const mollieClient = createMollieClient({
        apiKey: process.env.MOLLIE_API_KEY
    });
    
    try {
        const payment = await mollieClient.payments.get(paymentId);
        
        if (payment.status === 'paid') {
            // Payment successful - create booking in your system
            const customerId = payment.metadata.customerId;
            const bookingData = payment.metadata;
            
            await createBooking({
                customerId,
                ...bookingData,
                paymentId: payment.id,
                amount: payment.amount.value
            });
            
            // Send confirmation email
            await sendConfirmationEmail(customerId, bookingData);
        }
        
        return { statusCode: 200, body: 'OK' };
    } catch (error) {
        console.error('Webhook error:', error);
        return { statusCode: 500, body: 'Error' };
    }
};
```

## Environment Variables

Add to your backend `.env`:

```env
MOLLIE_API_KEY=test_xxxxxxxxxxxxxxxxxx  # Test key for development
# MOLLIE_API_KEY=live_xxxxxxxxxxxxxxxxxx  # Live key for production
API_BASE_URL=https://veramo.ch
```

## Mollie Dashboard Setup

1. Sign up at https://www.mollie.com/
2. Create a website profile
3. Get your API keys from **Developers → API Keys**
4. Test mode: Use `test_` key
5. Production: Use `live_` key (requires verification)

## Testing

### Test Cards (Test Mode):
- **Successful payment:** Card number `5555 5555 5555 4444`
- **Failed payment:** Card number `5555 5555 5555 5557`

### Test Flow:
1. iOS app creates payment
2. User redirected to Mollie checkout
3. User pays with test card
4. Mollie redirects back to app
5. App checks payment status
6. If paid, booking is confirmed

## Security Notes

✅ **Do's:**
- Validate session token for all requests
- Use webhook to confirm payments (don't trust client)
- Store Mollie API key in environment variables
- Use HTTPS for all communication
- Verify payment status server-side before creating booking

❌ **Don'ts:**
- Never expose Mollie API key to client
- Don't create booking without confirming payment
- Don't trust payment status from iOS app only
- Don't use test keys in production

## Production Checklist

- [ ] Mollie account verified
- [ ] Using live API key
- [ ] Webhook URL configured
- [ ] SSL certificate valid
- [ ] Payment confirmation emails working
- [ ] Refund process implemented
- [ ] Tested with real card (small amount)

## Support

- Mollie API Docs: https://docs.mollie.com/
- Mollie Dashboard: https://www.mollie.com/dashboard
- Test mode guide: https://docs.mollie.com/overview/testing
