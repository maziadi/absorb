package com.initsys.sigal.agent.agi;

import static org.junit.Assert.fail;
import static org.junit.Assert.assertEquals;

import org.junit.Before;
import org.junit.Test;

public class CallNormalizerImplTest {

    private CallNormalizerImpl normalizer = new CallNormalizerImpl();

    private CallContext callContext;


    public CallContext getCallContext(String calledNumber,
            String callingNumber, String callingName) {
      return getCallContext(calledNumber, callingNumber, null, callingName);
    }

    public CallContext getCallContext(String calledNumber, String callingNumber,
        String callingIdentityNumber, String callingName) {
        CallContext callContext = new CallContext();
        if (calledNumber != null) {
            callContext.setCalledNumber(calledNumber);
        }
        if (callingNumber != null) {
            callContext.setCallingNumber(callingNumber);
        }
        if (callingIdentityNumber != null) {
            callContext.setCallingIdentityNumber(callingIdentityNumber);
        }
        if (callingName != null) {
            callContext.setCallingName(callingName);
        }
        return callContext;
    }

    public CallNormalizerImpl getNormalizer() {
        return normalizer;
    }

    @Before
    public void setUp() {
    }

    @Test
    public void noCalledNumber() {
        try {
            getNormalizer().normalizeInbound(getCallContext(null, null, null),
                    "e164", null);
            fail("Should have thrown a CallException");
        } catch (OutgoingAccountException e) {
            // ok
        }
        try {
            getNormalizer().normalizeOutbound(getCallContext(null, null, null),
                    "e164");
            fail("Should have thrown a CallException");
        } catch (OutgoingAccountException e) {
            // ok
        }
    }

    @Test
    public void incorrectNumberingPlan() {
        try {
            getNormalizer().normalizeInbound(getCallContext(null, null, null),
                    "e.164", null);
            fail("Should have thrown a CallException");
        } catch (IncomingAccountException e) {
            // ok
        }
        try {
            getNormalizer().normalizeInbound(getCallContext(null, null, null),
                    "", null);
            fail("Should have thrown a CallException");
        } catch (IncomingAccountException e) {
            // ok
        }
        try {
            getNormalizer().normalizeOutbound(getCallContext(null, null, null),
                    "e.164");
            fail("Should have thrown a CallException");
        } catch (OutgoingAccountException e) {
            // ok
        }
        try {
            getNormalizer().normalizeOutbound(getCallContext(null, null, null),
                    "");
            fail("Should have thrown a CallException");
        } catch (OutgoingAccountException e) {
            // ok
        }
    }

    /**
     * If no calling number is present nor any default, then throw exception
     */
    @Test
    public void noCallingNumber() {
        this.callContext = getCallContext("33000000001", null, null);

        try {
            getNormalizer().normalizeInbound(this.callContext, "e164", null);
            fail("Should have thrown a CallException");
        } catch (IncomingAccountException e) {
            // ok
        }
    }

    /**
     * If no calling number is present normalize it with a default.
     */
    @Test
    public void normalizeInboundCallingNumberWithDefault() {
        this.callContext = getCallContext("33000000001", null, null);
        getNormalizer().normalizeInbound(this.callContext, "e164",
                "33123456789");

        assertEquals("callingNumber", "33123456789", this.callContext
                .getCallingNumber());
        assertEquals("effectiveCallingNumber", "33123456789", this.callContext
                .getEffectiveCallingNumber());
    }

    /**
     * Normalize inbound from national to e164
     */
    @Test
    public void normalizeInboundNational() {
        this.callContext = getCallContext("0123456789", "0123456788",
                "Jean Bon");
        getNormalizer().normalizeInbound(this.callContext, "national",
                "33000000001");

        assertEquals("calledNumber", "0123456789", this.callContext
                .getCalledNumber());
        assertEquals("callingNumber", "0123456788", this.callContext
                .getCallingNumber());
        assertEquals("effectiveCalledNumber", "33123456789", this.callContext
                .getEffectiveCalledNumber());
        assertEquals("effectiveCallingNumber", "33123456788", this.callContext
                .getEffectiveCallingNumber());
        assertEquals("callingName", "Jean Bon", this.callContext
                .getCallingName());
    }

    /**
     * Normalize inbound from national to e164
     */
    @Test
    public void normalizeInboundNational9() {
        this.callContext = getCallContext("123456789", "123456788", "Jean Bon");
        getNormalizer().normalizeInbound(this.callContext, "national9",
                "33000000001");

        assertEquals("calledNumber", "123456789", this.callContext
                .getCalledNumber());
        assertEquals("callingNumber", "123456788", this.callContext
                .getCallingNumber());
        assertEquals("effectiveCalledNumber", "33123456789", this.callContext
                .getEffectiveCalledNumber());
        assertEquals("effectiveCallingNumber", "33123456788", this.callContext
                .getEffectiveCallingNumber());
        assertEquals("callingName", "Jean Bon", this.callContext
                .getCallingName());
    }

    /**
     * Normalize inbound from national to e164 (beginning with double 0)
     */
    @Test
    public void normalizeInboundNational9Double0() {
        this.callContext = getCallContext("003456789", "003456788", "Jean Bon");
        getNormalizer().normalizeInbound(this.callContext, "national9", null);

        assertEquals("calledNumber", "003456789", this.callContext
                .getCalledNumber());
        assertEquals("callingNumber", "003456788", this.callContext
                .getCallingNumber());
        assertEquals("effectiveCalledNumber", "33003456789", this.callContext
                .getEffectiveCalledNumber());
        assertEquals("effectiveCallingNumber", "33003456788", this.callContext
                .getEffectiveCallingNumber());
        assertEquals("callingName", "Jean Bon", this.callContext
                .getCallingName());
    }

    /**
     * Normalize inbound from E.164
     */
    @Test
    public void normalizeInboundE164() {
        this.callContext = getCallContext("33123456789", "+33123456788",
                "Jean Bon");
        getNormalizer().normalizeInbound(this.callContext, "e164",
                "33000000001");

        assertEquals("calledNumber", "33123456789", this.callContext
                .getCalledNumber());
        assertEquals("callingNumber", "33123456788", this.callContext
                .getCallingNumber());
        assertEquals("effectiveCalledNumber", "33123456789", this.callContext
                .getEffectiveCalledNumber());
        assertEquals("effectiveCallingNumber", "33123456788", this.callContext
                .getEffectiveCallingNumber());
        assertEquals("callingName", "Jean Bon", this.callContext
                .getCallingName());
    }

    /**
     * Normalize outbound from E.164
     */
    @Test
    public void normalizeOutboundE164() {
        this.callContext = getCallContext("33123456789", "+33123456788",
                "+33123456780", "Jean Bon");
        getNormalizer().normalizeOutbound(this.callContext, "e164");

        assertEquals("calledNumber", "33123456789", this.callContext
                .getCalledNumber());
        assertEquals("callingNumber", "33123456788", this.callContext
                .getCallingNumber());
        assertEquals("callingIdentityNumber", "33123456780", this.callContext
                .getCallingIdentityNumber());
        assertEquals("effectiveCalledNumber", "33123456789", this.callContext
                .getEffectiveCalledNumber());
        assertEquals("effectiveCallingNumber", "+33123456788", this.callContext
                .getEffectiveCallingNumber());
        assertEquals("effectiveCallingIdentityNumber", "+33123456780",
            this.callContext.getEffectiveCallingIdentityNumber());
        assertEquals("callingName", "Jean Bon", this.callContext
                .getCallingName());
    }

    /**
     * Normalize outbound from E.164 to E.164+
     */
    @Test
    public void normalizeOutboundE164ToE164plus() {
        this.callContext = getCallContext("33123456789", "+33123456788",
                "+33123456780", "Jean Bon");
        getNormalizer().normalizeOutbound(this.callContext, "e164plus");

        assertEquals("calledNumber", "33123456789", this.callContext
                .getCalledNumber());
        assertEquals("callingNumber", "33123456788", this.callContext
                .getCallingNumber());
        assertEquals("callingIdentityNumber", "33123456780", this.callContext
                .getCallingIdentityNumber());
        assertEquals("effectiveCalledNumber", "+33123456789", this.callContext
                .getEffectiveCalledNumber());
        assertEquals("effectiveCallingNumber", "+33123456788", this.callContext
                .getEffectiveCallingNumber());
        assertEquals("effectiveCallingIdentityNumber", "+33123456780",
            this.callContext.getEffectiveCallingIdentityNumber());
        assertEquals("callingName", "Jean Bon", this.callContext
                .getCallingName());
    }

    /**
     * Normalize outbound from national
     */
    @Test
    public void normalizeOutboundNational() {
        this.callContext = getCallContext("33123456789", "33123456788",
                "33123456780", "Jean Bon");
        getNormalizer().normalizeOutbound(this.callContext, "national");

        assertEquals("calledNumber", "33123456789", this.callContext
                .getCalledNumber());
        assertEquals("callingNumber", "33123456788", this.callContext
                .getCallingNumber());
        assertEquals("callingIdentityNumber", "33123456780", this.callContext
                .getCallingIdentityNumber());
        assertEquals("effectiveCalledNumber", "0123456789", this.callContext
                .getEffectiveCalledNumber());
        assertEquals("effectiveCallingNumber", "0123456788", this.callContext
                .getEffectiveCallingNumber());
        assertEquals("effectiveCallingIdentityNumber", "0123456780",
            this.callContext.getEffectiveCallingIdentityNumber());
        assertEquals("callingName", "Jean Bon", this.callContext
                .getCallingName());
    }

    /**
     * Normalize outbound from national
     */
    @Test
    public void normalizeOutboundNational9() {
        this.callContext = getCallContext("33123456789", "33123456788",
                "33123456780", "Jean Bon");
        getNormalizer().normalizeOutbound(this.callContext, "national9");

        assertEquals("calledNumber", "33123456789", this.callContext
                .getCalledNumber());
        assertEquals("callingNumber", "33123456788", this.callContext
                .getCallingNumber());
        assertEquals("callingIdentityNumber", "33123456780", this.callContext
                .getCallingIdentityNumber());
        assertEquals("effectiveCalledNumber", "123456789", this.callContext
                .getEffectiveCalledNumber());
        assertEquals("effectiveCallingNumber", "123456788", this.callContext
                .getEffectiveCallingNumber());
        assertEquals("effectiveCallingIdentityNumber", "123456780",
            this.callContext.getEffectiveCallingIdentityNumber());
        assertEquals("callingName", "Jean Bon", this.callContext
                .getCallingName());
    }

}
