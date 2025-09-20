# Testing Instructions for AI Chat Feature

## How to Test the 30-Second Timer Feature

### 1. **Setup**
- Make sure you have the app running
- Ensure you have a Gemini API key configured (optional - works with fallback responses)

### 2. **Test Steps**

1. **Register/Login as Donor**
   - Open the app
   - Choose "I want to Donate" 
   - Complete donor registration

2. **Upload a Donation**
   - Go to "My Donations" tab
   - Tap the green "Donate Item" floating action button
   - Add an image (camera or gallery)
   - Fill in item details
   - Tap "Upload Donation"

3. **Wait for Timer (5 seconds for testing)**
   - Stay in the app after uploading
   - After 5 seconds, you should see a green notification banner
   - Notification should say: "Someone is interested in your donation!"

4. **Check Chat**
   - Tap "View Chats" on the notification OR
   - Tap the blue chat icon in bottom navigation (with red notification dot)
   - You should see a new conversation with an AI user
   - The AI should have already sent an initial message

5. **Test Chat Functionality**
   - Tap on the conversation to open chat
   - Send a message to the AI
   - AI should respond naturally about the donation
   - Conversation should maintain context

### 3. **Debug Information**

If the feature doesn't work, check the debug console for these messages:
- "Notification callback set" - when app starts
- "Donation added: [item name], scheduling AI conversation in 5 seconds" - when donation uploaded
- "Creating AI conversation for donation: [item name]" - when timer triggers
- "AI conversation created successfully" - when AI chat is ready
- "Showing notification" - when notification appears

### 4. **Expected Behavior**

✅ **What Should Happen:**
- Timer starts automatically after donation upload
- Notification appears after 5 seconds (30 in production)
- Chat tab gets a red notification dot
- AI conversation appears in chat list
- AI sends realistic, contextual messages
- Full chat functionality works

❌ **Troubleshooting:**
- If no notification: Check console for "No notification callback set"
- If timer doesn't start: Check for "Donation added" message
- If AI doesn't respond: Check Gemini API configuration
- If chat crashes: Check for missing conversation data

### 5. **Navigation Changes**

The app navigation has been updated:
- ✅ **Added**: Chat tab in bottom navigation (with notification badge)
- ✅ **Removed**: Donate tab (now accessible via FAB in My Donations)
- ✅ **Enhanced**: Floating action buttons with chat access

This provides a complete end-to-end test of the AI chat feature with 30-second automated engagement!
