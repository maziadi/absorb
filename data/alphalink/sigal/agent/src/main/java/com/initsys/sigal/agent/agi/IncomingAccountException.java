package com.initsys.sigal.agent.agi;

/**
 * Thrown when calling account is not found while handeling a call
 */
public class IncomingAccountException extends RuntimeException {

    /** Serial version UID */
    /* private static final long serialVersionUID = 7854951067763635494L; */

    public IncomingAccountException(String message, Throwable cause) {
        super(message, cause);
    }

    public IncomingAccountException(String message) {
        super(message);
    }

}
