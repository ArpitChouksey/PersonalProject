package com.company.spring_service.service;

import com.company.spring_service.entity.AuditLog;
import com.company.spring_service.event.UserCreatedEvent;
import com.company.spring_service.repository.AuditLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuditService {

    private final AuditLogRepository auditLogRepository;

    public void saveUserCreatedAudit(UserCreatedEvent event) {

        AuditLog audit = new AuditLog();

        audit.setEventType(event.getEventType().name());
        audit.setUserId(event.getUserId());
        audit.setEmail(event.getEmail());
        audit.setEventTime(event.getEventTime());
        audit.setStatus("SUCCESS");
        audit.setSource(event.getSource());

        auditLogRepository.save(audit);
    }
}
