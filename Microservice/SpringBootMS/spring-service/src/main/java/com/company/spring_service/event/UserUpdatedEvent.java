package com.company.spring_service.event;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UserUpdatedEvent extends BaseEvent {

    private Long userId;
    private String firstName;
    private String lastName;
    private String email;

    public UserUpdatedEvent(
            Long userId,
            String firstName,
            String lastName,
            String email,
            String source
    ) {

        super(EventType.USER_UPDATED, source);

        this.userId = userId;
        this.firstName = firstName;
        this.lastName = lastName;
        this.email = email;
    }

}
