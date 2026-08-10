package com.company.spring_service.event;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class UserCreatedEvent extends BaseEvent {

    private Long userId;
    private String firstName;
    private String lastName;
    private String email;

    public UserCreatedEvent(
            Long userId,
            String firstName,
            String lastName,
            String email,
            String source
    ) {

        super(EventType.USER_CREATED, source);

        this.userId = userId;
        this.firstName = firstName;
        this.lastName = lastName;
        this.email = email;
    }

}
