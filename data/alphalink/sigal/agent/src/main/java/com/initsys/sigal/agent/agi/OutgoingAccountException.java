package com.initsys.sigal.agent.agi;

/**
 * Thrown when called account is not found while handeling a call
 */
public class OutgoingAccountException extends RuntimeException {

    /** Serial version UID */
    /* private static final long serialVersionUID = 7854951067763635494L; */

    public OutgoingAccountException(String message, Throwable cause) {
        super(message, cause);
    }

    public OutgoingAccountException(String message) {
        super(message);
    }

}
