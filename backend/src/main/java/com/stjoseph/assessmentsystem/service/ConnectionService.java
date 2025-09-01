package com.stjoseph.assessmentsystem.service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.stjoseph.assessmentsystem.model.Alumni;
import com.stjoseph.assessmentsystem.model.Connection;
import com.stjoseph.assessmentsystem.model.User;
import com.stjoseph.assessmentsystem.repository.AlumniRepository;
import com.stjoseph.assessmentsystem.repository.ConnectionRepository;
import com.stjoseph.assessmentsystem.repository.UserRepository;

@Service
public class ConnectionService {
    
    @Autowired
    private ConnectionRepository connectionRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private AlumniRepository alumniRepository;
    
    @Autowired
    private NotificationService notificationService;
    
    public Connection sendConnectionRequest(String senderId, String recipientId, String message) {
        // Check if connection already exists
        Optional<Connection> existingConnection = connectionRepository.findConnectionBetweenUsers(senderId, recipientId);
        if (existingConnection.isPresent()) {
            throw new RuntimeException("You are already connected or have a pending request with this user");
        }
        
        // Verify sender exists (could be in User or Alumni table)
        String senderName = null;
        Optional<User> senderUser = userRepository.findById(senderId);
        if (senderUser.isPresent()) {
            senderName = senderUser.get().getName();
        } else {
            // Check Alumni table for sender
            Optional<Alumni> senderAlumni = alumniRepository.findById(senderId);
            if (senderAlumni.isPresent() && senderAlumni.get().getStatus() == Alumni.AlumniStatus.APPROVED) {
                senderName = senderAlumni.get().getName();
            } else {
                throw new RuntimeException("Sender not found or not approved");
            }
        }
        
        // Verify recipient exists (could be in User or Alumni table)
        String recipientName = null;
        Optional<User> recipientUser = userRepository.findById(recipientId);
        if (recipientUser.isPresent()) {
            recipientName = recipientUser.get().getName();
        } else {
            // Check Alumni table for recipient
            Optional<Alumni> recipientAlumni = alumniRepository.findById(recipientId);
            if (recipientAlumni.isPresent() && recipientAlumni.get().getStatus() == Alumni.AlumniStatus.APPROVED) {
                recipientName = recipientAlumni.get().getName();
            } else {
                throw new RuntimeException("Recipient not found or not approved");
            }
        }
        
        // Create new connection with PENDING status (proper LinkedIn-like system)
        Connection connection = new Connection(senderId, recipientId, message);
        connection.setStatus(Connection.ConnectionStatus.PENDING); // Keep as pending until recipient responds
        Connection savedConnection = connectionRepository.save(connection);
        
        // Send notification to recipient about the connection request
        try {
            notificationService.createConnectionRequestNotification(recipientId, senderId, senderName);
            System.out.println("ConnectionService: Sent connection request notification to " + recipientName + " from " + senderName);
        } catch (Exception e) {
            System.err.println("Failed to send connection request notification: " + e.getMessage());
        }
        
        return savedConnection;
    }
    
    public Connection acceptConnectionRequest(String connectionId, String userId) {
        Optional<Connection> connectionOpt = connectionRepository.findById(connectionId);
        if (connectionOpt.isEmpty()) {
            throw new RuntimeException("Connection request not found");
        }
        
        Connection connection = connectionOpt.get();
        
        // Verify user is the recipient
        if (!connection.getRecipientId().equals(userId)) {
            throw new RuntimeException("Unauthorized to accept this connection request");
        }
        
        // Update connection status
        connection.setStatus(Connection.ConnectionStatus.ACCEPTED);
        connection.setRespondedAt(LocalDateTime.now());
        
        Connection savedConnection = connectionRepository.save(connection);
        
        // Update connection counts for both users
        updateConnectionCounts(connection.getSenderId(), connection.getRecipientId());
        
        // Send notification to sender
        try {
            String recipientName = getUserName(connection.getRecipientId());
            if (recipientName != null) {
                notificationService.createConnectionAcceptedNotification(
                    connection.getSenderId(), connection.getRecipientId(), recipientName);
            }
        } catch (Exception e) {
            System.err.println("Failed to send connection accepted notification: " + e.getMessage());
        }
        
        return savedConnection;
    }
    
    public Connection rejectConnectionRequest(String connectionId, String userId) {
        Optional<Connection> connectionOpt = connectionRepository.findById(connectionId);
        if (connectionOpt.isEmpty()) {
            throw new RuntimeException("Connection request not found");
        }
        
        Connection connection = connectionOpt.get();
        
        // Verify user is the recipient
        if (!connection.getRecipientId().equals(userId)) {
            throw new RuntimeException("Unauthorized to reject this connection request");
        }
        
        // Update connection status
        connection.setStatus(Connection.ConnectionStatus.REJECTED);
        connection.setRespondedAt(LocalDateTime.now());
        
        return connectionRepository.save(connection);
    }
    
    public List<Connection> getPendingConnectionRequests(String userId) {
        System.out.println("ConnectionService: Getting pending requests for user: " + userId);
        List<Connection> pending = connectionRepository.findPendingConnectionRequests(userId);
        System.out.println("ConnectionService: Found " + pending.size() + " pending connection requests");
        return pending;
    }
    
    public List<Connection> getAcceptedConnections(String userId) {
        return connectionRepository.findAcceptedConnectionsByUserId(userId);
    }
    
    public String getConnectionStatus(String userId1, String userId2) {
        Optional<Connection> connection = connectionRepository.findConnectionBetweenUsers(userId1, userId2);
        System.out.println("ConnectionService: Checking connection between " + userId1 + " and " + userId2);
        if (connection.isEmpty()) {
            System.out.println("ConnectionService: No connection found, status: none");
            return "none";
        }
        
        Connection conn = connection.get();
        System.out.println("ConnectionService: Found connection with status: " + conn.getStatus());
        System.out.println("ConnectionService: Sender: " + conn.getSenderId() + ", Recipient: " + conn.getRecipientId());
        
        switch (conn.getStatus()) {
            case PENDING:
                // If current user is the sender, show "pending"
                // If current user is the recipient, they should see it in their pending requests
                if (conn.getSenderId().equals(userId1)) {
                    System.out.println("ConnectionService: User is sender, status: pending");
                    return "pending";
                } else {
                    System.out.println("ConnectionService: User is recipient, status: none (will see in pending requests)");
                    return "none"; // Recipient sees it in their pending requests section
                }
            case ACCEPTED:
                System.out.println("ConnectionService: Connection accepted, status: connected");
                return "connected";
            case REJECTED:
                System.out.println("ConnectionService: Connection rejected, status: none");
                return "none";
            default:
                System.out.println("ConnectionService: Unknown status, defaulting to none");
                return "none";
        }
    }
    
    public long getConnectionCount(String userId) {
        return connectionRepository.findAcceptedConnectionsByUserId(userId).size();
    }
    
    // Helper method to get user name from either User or Alumni table
    private String getUserName(String userId) {
        // First try User table
        Optional<User> user = userRepository.findById(userId);
        if (user.isPresent()) {
            return user.get().getName();
        }
        
        // Then try Alumni table
        Optional<Alumni> alumni = alumniRepository.findById(userId);
        if (alumni.isPresent()) {
            return alumni.get().getName();
        }
        
        return null;
    }
    
    // Helper method to update connection counts for both users
    private void updateConnectionCounts(String senderId, String recipientId) {
        try {
            System.out.println("ConnectionService: Updating connection counts for sender: " + senderId + " and recipient: " + recipientId);
            
            // Update sender's connection count
            Optional<User> senderOpt = userRepository.findById(senderId);
            if (senderOpt.isPresent()) {
                User sender = senderOpt.get();
                long senderConnections = getConnectionCount(senderId);
                sender.setConnectionCount((int) senderConnections);
                userRepository.save(sender);
                System.out.println("Updated connection count for sender " + sender.getName() + ": " + senderConnections);
            } else {
                // Check if sender is in Alumni table
                Optional<Alumni> senderAlumniOpt = alumniRepository.findById(senderId);
                if (senderAlumniOpt.isPresent()) {
                    System.out.println("Sender found in Alumni table, but Alumni table doesn't have connection count field");
                }
            }
            
            // Update recipient's connection count
            Optional<User> recipientOpt = userRepository.findById(recipientId);
            if (recipientOpt.isPresent()) {
                User recipient = recipientOpt.get();
                long recipientConnections = getConnectionCount(recipientId);
                recipient.setConnectionCount((int) recipientConnections);
                userRepository.save(recipient);
                System.out.println("Updated connection count for recipient " + recipient.getName() + ": " + recipientConnections);
            } else {
                // Check if recipient is in Alumni table
                Optional<Alumni> recipientAlumniOpt = alumniRepository.findById(recipientId);
                if (recipientAlumniOpt.isPresent()) {
                    System.out.println("Recipient found in Alumni table, but Alumni table doesn't have connection count field");
                }
            }
        } catch (Exception e) {
            System.err.println("Error updating connection counts: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    // Helper method to check if user exists in either table
    public boolean userExists(String userId) {
        // Check User table first
        if (userRepository.findById(userId).isPresent()) {
            return true;
        }
        
        // Check Alumni table
        Optional<Alumni> alumni = alumniRepository.findById(userId);
        return alumni.isPresent() && alumni.get().getStatus() == Alumni.AlumniStatus.APPROVED;
    }
    
    // Helper method to get user details from either table
    public UserDetails getUserDetails(String userId) {
        // First try User table
        Optional<User> user = userRepository.findById(userId);
        if (user.isPresent()) {
            User u = user.get();
            return new UserDetails(u.getId(), u.getName(), u.getEmail(), u.getRole().name());
        }
        
        // Then try Alumni table
        Optional<Alumni> alumni = alumniRepository.findById(userId);
        if (alumni.isPresent() && alumni.get().getStatus() == Alumni.AlumniStatus.APPROVED) {
            Alumni a = alumni.get();
            return new UserDetails(a.getId(), a.getName(), a.getEmail(), "ALUMNI");
        }
        
        return null;
    }
    
    // Inner class for user details
    public static class UserDetails {
        private String id;
        private String name;
        private String email;
        private String role;
        
        public UserDetails(String id, String name, String email, String role) {
            this.id = id;
            this.name = name;
            this.email = email;
            this.role = role;
        }
        
        // Getters
        public String getId() { return id; }
        public String getName() { return name; }
        public String getEmail() { return email; }
        public String getRole() { return role; }
    }
}