# SMS Authentication Backend Implementation Guide

## Overview
This document describes the backend endpoints needed to support SMS-based authentication in the Veramo iOS app.

## Required Endpoints

### 1. Send SMS Verification Code

**Endpoint:** `POST /.netlify/functions/sms-code-send`

**Request Body:**
```json
{
  "phone": "+41791234567"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Verification code sent"
}
```

**Response (Error):**
```json
{
  "success": false,
  "message": "Error description"
}
```

**Status Codes:**
- `200` - Code sent successfully
- `400` - Invalid phone number
- `429` - Too many requests (rate limiting)
- `500` - Server error

**Implementation Notes:**
- Generate a random 6-digit code
- Store the code with the phone number (with expiration, e.g., 10 minutes)
- Send SMS using a service like Twilio, AWS SNS, or similar
- Implement rate limiting to prevent abuse (e.g., max 3 codes per hour per phone)
- Consider storing the code hashed for security

---

### 2. Verify SMS Code

**Endpoint:** `POST /.netlify/functions/sms-code-verify`

**Request Body:**
```json
{
  "phone": "+41791234567",
  "code": "123456"
}
```

**Response (Success):**
```json
{
  "success": true,
  "sessionToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "customer": {
    "id": 123,
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+41791234567"
  }
}
```

**Response (Invalid Code):**
```json
{
  "success": false,
  "error": "Invalid or expired verification code"
}
```

**Status Codes:**
- `200` - Code verified successfully
- `401` - Invalid or expired code
- `404` - Phone number not found in customer database
- `500` - Server error

**Implementation Notes:**
- Look up the stored code for the phone number
- Check if the code matches and hasn't expired
- If valid, look up or create customer record by phone number
- Generate a session token (JWT recommended)
- Delete or invalidate the used verification code
- Implement attempt limiting (e.g., max 5 attempts before code invalidation)

---

## Security Considerations

1. **Rate Limiting:** Implement aggressive rate limiting on code sending to prevent SMS spam
2. **Code Expiration:** Codes should expire after 10 minutes
3. **Attempt Limiting:** Invalidate code after 5 failed verification attempts
4. **Phone Validation:** Validate phone number format before sending SMS
5. **Session Tokens:** Use secure JWT tokens with appropriate expiration
6. **Logging:** Log all authentication attempts for security auditing

---

## SMS Service Integration

Consider using one of these SMS providers:
- **Twilio** - Popular, reliable, good documentation
- **AWS SNS** - If already using AWS
- **Vonage (Nexmo)** - Good pricing
- **MessageBird** - EU-based option

---

## Example Code Format (Reference)

The iOS app expects phone numbers in international format (E.164):
- ✅ `+41791234567`
- ✅ `+14155551234`
- ❌ `079 123 45 67` (needs country code)

Consider using a library like `libphonenumber` to parse and validate phone numbers on the backend.

---

## Migration Notes

If you're replacing the existing magic link system:
- Consider keeping both systems active initially
- Monitor which method users prefer
- Eventually deprecate the less-used method

If you want both to coexist:
- Users can choose their preferred authentication method
- Link accounts by email/phone in the customer database
