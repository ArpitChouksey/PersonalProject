package com.company.spring_service.event;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UserDeletedEvent extends BaseEvent {

    private Long userId;
    private String email;

    public UserDeletedEvent(
            Long userId,
            String email,
            String source
    ) {

        super(EventType.USER_DELETED, source);

        this.userId = userId;
        this.email = email;
    }

}
