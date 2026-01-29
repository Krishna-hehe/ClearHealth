# Plan: Lab Result & Diet Integration for Ask LabSense

> **Task Slug:** `lab-chat-integration`
> **Goal:** Integrate rich lab result context, abnormality insights, and dietary recommendations into the "Ask LabSense" chat experience.

---

## 🏗️ Phase 1: Knowledge & Data Engineering

### 1.1 Enhance Prompt Engineering (The Brain)

The current prompt in `ai_service.dart` is too basic ("LabSense AI Assistant"). We need to engineer a sophisticated system prompt.

- **Objective:** Create a comprehensive "System Prompt" that defines the AI's persona.
- **Key Instructions to Add:**
  - "You are an expert Medical AI assistant."
  - "When a user asks about diet, analyze their ABNORMAL lab results first."
  - "If LDL is high => suggest low saturated fat, high fiber."
  - "If A1C is high => suggest low glycemic index foods."
  - "Always add a disclaimer: 'Consult your doctor before making major changes'."

### 1.2 Context Injection Strategy (The Data)

Ensure `ChatService` and `AiService` receive the full context.

- **Current State:** `healthContext` is passed but minified.
- **Action:** Ensure `abnormal_labs` includes units and reference ranges, not just names/values, so the AI knows *how* abnormal it is.

---

## 🛠️ Phase 2: Implementation

### 2.1 Update `AiService`

- **File:** `lib/core/ai_service.dart`
- **Task:** Rewrite `getChatResponseWithContext` prompt.
- **Details:**
  - Structure the prompt with sections: `[ROLE]`, `[CONTEXT]`, `[ABNORMALITIES]`, `[INSTRUCTIONS]`.
  - Add specific logic for dietary queries.

### 2.2 Update `HealthChatPage` (UI)

- **File:** `lib/features/chat/health_chat_page.dart` (or equivalent)
- **Task:** Ensure `healthContext` is fully populated when calling `chat()`.
- **Details:**
  - Fetch latest `abnormal` results from cache or Supabase.
  - Pass them into the `chat()` method.

---

## 🧪 Phase 3: Verification & Testing

### 3.1 Test Cases

1. **General Query:** "Hello" -> Standard greeting.
2. **Context Query:** "Explain my latest results" -> Must reference the specific values in the context.
3. **Diet Query:** "What should I eat?" -> Must look at *Abnormal* results (e.g., High Cholesterol) and give specific advice (e.g., "Since your LDL is high...").
4. **Safety Check:** Ensure disclaimers are present.

---

## ✅ Verification Checklist

- [ ] System prompt includes dietary expertise instructions.
- [ ] Chat consistently references "High/Low" status in detailed explanations.
- [ ] Dietary advice is specific to the user's actual abnormal markers (not generic).
- [ ] No regression in vector search speed.

---

## 🚀 Execution Order

1. **Refine Prompt**: Edit `ai_service.dart` to upgrade the system prompt.
2. **Verify Context**: specific debug log to see what `healthContext` string looks like.
3. **Test Flow**: Run the app and ask "What should I eat based on my results?".
