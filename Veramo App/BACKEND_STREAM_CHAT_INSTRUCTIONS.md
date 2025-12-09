# Backend Instructions: Stream Chat Token Generation

## Overview
The iOS app needs an endpoint to generate Stream Chat authentication tokens for customers. This allows customers to connect to Stream Chat and message support.

## Required Endpoint

### POST `/stream-chat/token`

**Purpose:** Generate a Stream Chat token for an authenticated customer

**Authentication:** Requires valid session token

**Headers:**
```
Authorization: Bearer {session_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "customer_id": 123
}
```

**Response (Success - 200):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (Error - 401):**
```json
{
  "error": "Unauthorized",
  "message": "Invalid or expired session token"
}
```

**Response (Error - 403):**
```json
{
  "error": "Forbidden", 
  "message": "Customer ID does not match authenticated user"
}
```

## Implementation Steps

### 1. Install Stream Chat Server SDK

**PHP (Laravel):**
```bash
composer require get-stream/stream-chat
```

**Node.js:**
```bash
npm install stream-chat
```

**Python:**
```bash
pip install stream-chat
```

### 2. Store Stream Credentials

Add these to your environment variables:

```env
STREAM_API_KEY=j46xbwqsrzsk
STREAM_API_SECRET=your_stream_api_secret_here
```

⚠️ **Important:** The API secret should NEVER be exposed to the client app!

### 3. Create the Endpoint

**PHP (Laravel) Example:**

```php
use GetStream\StreamChat\Client as StreamClient;

Route::post('/stream-chat/token', function (Request $request) {
    // 1. Validate session token
    $user = auth()->user();
    if (!$user) {
        return response()->json(['error' => 'Unauthorized'], 401);
    }
    
    // 2. Verify customer_id matches authenticated user
    $customerId = $request->input('customer_id');
    if ($user->id !== $customerId) {
        return response()->json(['error' => 'Forbidden'], 403);
    }
    
    // 3. Initialize Stream client
    $client = new StreamClient(
        env('STREAM_API_KEY'),
        env('STREAM_API_SECRET')
    );
    
    // 4. Generate token for this customer
    $userId = "customer-{$customerId}";
    $token = $client->createToken($userId);
    
    // 5. Return token
    return response()->json(['token' => $token]);
});
```

**Node.js (Express) Example:**

```javascript
const StreamChat = require('stream-chat').StreamChat;

app.post('/stream-chat/token', async (req, res) => {
    try {
        // 1. Validate session token (use your existing auth middleware)
        if (!req.user) {
            return res.status(401).json({ error: 'Unauthorized' });
        }
        
        // 2. Verify customer_id matches authenticated user
        const { customer_id } = req.body;
        if (req.user.id !== customer_id) {
            return res.status(403).json({ error: 'Forbidden' });
        }
        
        // 3. Initialize Stream client
        const client = StreamChat.getInstance(
            process.env.STREAM_API_KEY,
            process.env.STREAM_API_SECRET
        );
        
        // 4. Generate token for this customer
        const userId = `customer-${customer_id}`;
        const token = client.createToken(userId);
        
        // 5. Return token
        res.json({ token });
    } catch (error) {
        console.error('Stream token generation error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});
```

**Python (FastAPI) Example:**

```python
from stream_chat import StreamChat
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

router = APIRouter()

class TokenRequest(BaseModel):
    customer_id: int

@router.post("/stream-chat/token")
async def generate_stream_token(
    request: TokenRequest,
    current_user = Depends(get_current_user)  # Your auth dependency
):
    # 1. Verify customer_id matches authenticated user
    if current_user.id != request.customer_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    
    # 2. Initialize Stream client
    client = StreamChat(
        api_key=os.getenv("STREAM_API_KEY"),
        api_secret=os.getenv("STREAM_API_SECRET")
    )
    
    # 3. Generate token for this customer
    user_id = f"customer-{request.customer_id}"
    token = client.create_token(user_id)
    
    # 4. Return token
    return {"token": token}
```

## Important Security Notes

### ✅ Do's:
- Always validate the session token first
- Verify customer_id matches the authenticated user
- Store API secret in environment variables
- Use HTTPS for all communication
- Log token generation for auditing

### ❌ Don'ts:
- Never expose the Stream API secret to the client
- Don't generate tokens without authentication
- Don't allow customers to request tokens for other customers
- Don't hardcode credentials in source code

## User ID Format

The user ID MUST follow this format:
```
customer-{customer_id}
```

Examples:
- Customer ID 123 → Stream User ID: `customer-123`
- Customer ID 456 → Stream User ID: `customer-456`

This format is used by the iOS app to identify users consistently.

## Testing

### Test Request:
```bash
curl -X POST https://api.veramo.ch/stream-chat/token \
  -H "Authorization: Bearer {valid_session_token}" \
  -H "Content-Type: application/json" \
  -d '{"customer_id": 123}'
```

### Expected Response:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiY3VzdG9tZXItMTIzIn0..."
}
```

### Verify Token:
The token should be a valid JWT that:
- Contains user_id: `customer-{id}`
- Is signed with your Stream API secret
- Doesn't expire (or has long expiry)

## Support & Questions

If you encounter issues:

1. **Invalid API secret**: Verify credentials in Stream Dashboard
2. **Token validation errors**: Check user ID format matches `customer-{id}`
3. **CORS issues**: Ensure your API allows requests from the iOS app

Stream Chat Server SDK Documentation:
- PHP: https://getstream.io/chat/docs/php/
- Node.js: https://getstream.io/chat/docs/node/
- Python: https://getstream.io/chat/docs/python/

## Deployment Checklist

Before deploying to production:

- [ ] Stream API secret stored in environment variables
- [ ] Endpoint requires authentication
- [ ] Customer ID validation implemented
- [ ] Error handling implemented
- [ ] HTTPS enabled
- [ ] Rate limiting configured (optional but recommended)
- [ ] Logging enabled for debugging
- [ ] Tested with real customer accounts
