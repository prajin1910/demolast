package com.stjoseph.assessmentsystem.service;

import com.stjoseph.assessmentsystem.dto.ChatRequest;
import com.stjoseph.assessmentsystem.model.ChatMessage;
import com.stjoseph.assessmentsystem.model.User;
import com.stjoseph.assessmentsystem.repository.ChatMessageRepository;
import com.stjoseph.assessmentsystem.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class ChatService {
    
    @Autowired
    private ChatMessageRepository chatMessageRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private AIService aiService;
    
    @Autowired
    private EmailService emailService;
    
    @Autowired
    private ActivityService activityService;
    
    public List<Map<String, Object>> getConversations(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Get all chat messages involving this user
        List<ChatMessage> allMessages = chatMessageRepository.findByUserInvolved(user.getId());
        
        // Group by conversation partner
        Map<String, List<ChatMessage>> conversationMap = new HashMap<>();
        
        for (ChatMessage message : allMessages) {
            String partnerId = message.getSenderId().equals(user.getId()) ? 
                              message.getReceiverId() : message.getSenderId();
            
            if (!"AI".equals(partnerId)) { // Exclude AI conversations
                conversationMap.computeIfAbsent(partnerId, k -> new ArrayList<>()).add(message);
            }
        }
        
        // Create conversation objects
        List<Map<String, Object>> conversations = new ArrayList<>();
        
        for (Map.Entry<String, List<ChatMessage>> entry : conversationMap.entrySet()) {
            String partnerId = entry.getKey();
            List<ChatMessage> messages = entry.getValue();
            
            User partner = userRepository.findById(partnerId).orElse(null);
            if (partner == null) continue;
            
            // Get latest message
            ChatMessage latestMessage = messages.stream()
                    .max((m1, m2) -> m1.getTimestamp().compareTo(m2.getTimestamp()))
                    .orElse(null);
            
            // Count unread messages
            long unreadCount = messages.stream()
                    .filter(m -> !m.isRead() && !m.getSenderId().equals(user.getId()))
                    .count();
            
            Map<String, Object> conversation = new HashMap<>();
            
            Map<String, Object> userMap = new HashMap<>();
            userMap.put("id", partner.getId());
            userMap.put("name", partner.getName());
            userMap.put("email", partner.getEmail());
            userMap.put("role", partner.getRole().name());
            userMap.put("department", partner.getDepartment());
            
            conversation.put("user", userMap);
            conversation.put("lastMessage", latestMessage);
            conversation.put("unreadCount", unreadCount);
            
            conversations.add(conversation);
        }
        
        // Sort by latest message timestamp
        conversations.sort((c1, c2) -> {
            ChatMessage m1 = (ChatMessage) c1.get("lastMessage");
            ChatMessage m2 = (ChatMessage) c2.get("lastMessage");
            if (m1 == null && m2 == null) return 0;
            if (m1 == null) return 1;
            if (m2 == null) return -1;
            return m2.getTimestamp().compareTo(m1.getTimestamp());
        });
        
        return conversations;
    }
    
    public List<Map<String, Object>> getAllChatUsers(String userEmail) {
        User currentUser = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Get all users except current user
        List<User> allUsers = userRepository.findAll().stream()
                .filter(user -> !user.getId().equals(currentUser.getId()) && user.isVerified())
                .collect(Collectors.toList());
        
        List<Map<String, Object>> userMaps = new ArrayList<>();
        
        for (User user : allUsers) {
            Map<String, Object> userMap = new HashMap<>();
            userMap.put("id", user.getId());
            userMap.put("name", user.getName());
            userMap.put("email", user.getEmail());
            userMap.put("role", user.getRole().name());
            userMap.put("department", user.getDepartment());
            userMaps.add(userMap);
        }
        
        return userMaps;
    }
    
    public void markMessagesAsRead(String userEmail, String partnerId) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Update messages as read using a custom query approach
        List<ChatMessage> unreadMessages = chatMessageRepository.findAll().stream()
                .filter(msg -> msg.getSenderId().equals(partnerId) && 
                              msg.getReceiverId().equals(user.getId()) && 
                              !msg.isRead())
                .collect(Collectors.toList());
        
        unreadMessages.forEach(msg -> {
            msg.setRead(true);
            chatMessageRepository.save(msg);
        });
    }
    
    public String chatWithAI(ChatRequest request, String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        String response = aiService.generateChatResponse(request);
        
        // Save user message
        ChatMessage userMessage = new ChatMessage();
        userMessage.setSenderId(user.getId());
        userMessage.setSenderName(user.getName());
        userMessage.setReceiverId("AI");
        userMessage.setReceiverName("AI Assistant");
        userMessage.setMessage(request.getMessage());
        userMessage.setType(ChatMessage.MessageType.AI_CHAT);
        chatMessageRepository.save(userMessage);
        
        // Save AI response
        ChatMessage aiMessage = new ChatMessage();
        aiMessage.setSenderId("AI");
        aiMessage.setSenderName("AI Assistant");
        aiMessage.setReceiverId(user.getId());
        aiMessage.setReceiverName(user.getName());
        aiMessage.setMessage(response);
        aiMessage.setType(ChatMessage.MessageType.AI_CHAT);
        chatMessageRepository.save(aiMessage);
        
        // Log activity
        try {
            activityService.logActivityByUserId(user.getId(), "AI_CHAT", "Chatted with AI assistant");
            System.out.println("ChatService: Activity logged for AI chat");
        } catch (Exception e) {
            System.err.println("ChatService: Failed to log AI chat activity: " + e.getMessage());
        }
        
        return response;
    }
    
    public ChatMessage sendMessage(String receiverId, String message, String senderEmail) {
        User sender = userRepository.findByEmail(senderEmail)
                .orElseThrow(() -> new RuntimeException("Sender not found"));
        
        User receiver = userRepository.findById(receiverId)
                .orElseThrow(() -> new RuntimeException("Receiver not found"));
        
        ChatMessage chatMessage = new ChatMessage();
        chatMessage.setSenderId(sender.getId());
        chatMessage.setSenderName(sender.getName());
        chatMessage.setReceiverId(receiver.getId());
        chatMessage.setReceiverName(receiver.getName());
        chatMessage.setMessage(message);
        chatMessage.setType(ChatMessage.MessageType.USER_TO_USER);
        
        ChatMessage saved = chatMessageRepository.save(chatMessage);
        
        // Send email notification
        emailService.sendChatNotification(receiver.getEmail(), sender.getName(), message);
        
        // Log activity for both users
        String activityDesc = "Sent message to " + receiver.getName();
        if (receiver.getRole() == User.UserRole.ALUMNI) {
            try {
                activityService.logActivityByUserId(sender.getId(), "ALUMNI_CHAT", activityDesc);
                System.out.println("ChatService: Activity logged for alumni chat");
            } catch (Exception e) {
                System.err.println("ChatService: Failed to log alumni chat activity: " + e.getMessage());
            }
        } else if (receiver.getRole() == User.UserRole.PROFESSOR) {
            try {
                activityService.logActivityByUserId(sender.getId(), "PROFESSOR_CHAT", activityDesc);
                System.out.println("ChatService: Activity logged for professor chat");
            } catch (Exception e) {
                System.err.println("ChatService: Failed to log professor chat activity: " + e.getMessage());
            }
        }
        
        return saved;
    }
    
    public List<ChatMessage> getChatHistory(String userEmail, String otherUserId) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        return chatMessageRepository.findChatMessages(
                user.getId(), 
                otherUserId, 
                PageRequest.of(0, 50, Sort.by("timestamp").descending())
        );
    }
}