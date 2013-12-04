package com.initsys.sigal.agent;

import static junit.framework.Assert.assertEquals;
import static junit.framework.Assert.assertFalse;
import static junit.framework.Assert.assertTrue;
import static junit.framework.Assert.fail;
import static org.easymock.EasyMock.createStrictMock;
import static org.easymock.EasyMock.expect;
import static org.easymock.EasyMock.isA;

import java.util.concurrent.TimeoutException;

import javax.jms.Queue;
import javax.jms.Topic;
import java.util.Date;

import org.easymock.EasyMock;
import org.easymock.IMocksControl;
import org.junit.Before;
import org.junit.Test;

import com.initsys.sigal.SigalTemplate;
import com.initsys.sigal.protocol.Sigal.EmdbQueryRequest;
import com.initsys.sigal.protocol.Sigal.EmdbQueryResponse;

public class FailoverSigalAgentMessagingGatewayTest {

    private SigalTemplate primaryTemplate;

    private SigalTemplate secondaryTemplate;

    private FailoverSigalAgentMessagingGateway gateway;

    private IMocksControl mockCtrl;
    public IMocksControl getMockCtrl() {
        return mockCtrl;
    }
    public void setMockCtrl(IMocksControl mockCtrl) {
        this.mockCtrl = mockCtrl;
    }

    @Before
    public void setUp() {
        setMockCtrl(EasyMock.createStrictControl());
        /* this.primaryTemplate = createStrictMock(SigalTemplate.class); */
        this.primaryTemplate = getMockCtrl().createMock(SigalTemplate.class);
        /* this.secondaryTemplate = createStrictMock(SigalTemplate.class); */
        this.secondaryTemplate = getMockCtrl().createMock(SigalTemplate.class);
        this.gateway = new FailoverSigalAgentMessagingGateway();
        this.gateway.setPrimaryTemplate(primaryTemplate);
        this.gateway.setSecondaryTemplate(secondaryTemplate);
    }

    private void replay() {
        /* EasyMock.replay(this.primaryTemplate, this.secondaryTemplate); */
        getMockCtrl().replay();
    }

    private void verify() {
        /* EasyMock.verify(this.primaryTemplate, this.secondaryTemplate); */
        getMockCtrl().verify();
    }

    @Test
    public void testFailover() throws TimeoutException {
        this.gateway.setMaxFailureCount(2);
        expect(primaryTemplate.call(isA(EmdbQueryRequest.class))).andThrow(
                new TimeoutException("too long"));
        expect(primaryTemplate.call(isA(EmdbQueryRequest.class))).andThrow(
                new TimeoutException("too long"));
        replay();
        timeoutCall();
        assertFalse("not yet failed over", this.gateway.isFailedOver());
        assertEquals(1, this.gateway.getFailureCount());
        timeoutCall();
        assertTrue("failed over", this.gateway.isFailedOver());
        assertEquals(0, this.gateway.getFailureCount());
        verify();
    }

    @Test
    public void testAlmostFailoverThenReFailover() throws TimeoutException {
        EmdbQueryResponse response = EmdbQueryResponse.newBuilder().setVersion(
                1).build();
        TimeoutException throwable = new TimeoutException("too long");

        this.gateway.setMaxFailureCount(3);

        expect(primaryTemplate.call(isA(EmdbQueryRequest.class))).andThrow(
                throwable);
        expect(primaryTemplate.call(isA(EmdbQueryRequest.class))).andReturn(
                response);
        expect(primaryTemplate.call(isA(EmdbQueryRequest.class))).andThrow(
                throwable).times(3);
        expect(secondaryTemplate.call(isA(EmdbQueryRequest.class))).andThrow(
                throwable);
        expect(secondaryTemplate.call(isA(EmdbQueryRequest.class))).andReturn(
                response);
        expect(secondaryTemplate.call(isA(EmdbQueryRequest.class))).andThrow(
                throwable).times(3);
        expect(primaryTemplate.call(isA(EmdbQueryRequest.class))).andThrow(
                throwable).times(3);

        replay();
        timeoutCall();
        assertEquals(1, this.gateway.getFailureCount());
        assertFalse("not yet failed over", this.gateway.isFailedOver());
        this.gateway.queryEmergency("test", "test");
        assertEquals(0, this.gateway.getFailureCount());
        assertFalse("not failed over", this.gateway.isFailedOver());
        timeoutCall();
        assertEquals(1, this.gateway.getFailureCount());
        assertFalse("not failed over either", this.gateway.isFailedOver());

        timeoutCall();
        assertEquals(2, this.gateway.getFailureCount());

        timeoutCall();
        assertEquals(0, this.gateway.getFailureCount());
        assertTrue("failed over", this.gateway.isFailedOver());
        assertEquals(0, this.gateway.getFailureCount());

        // Test non-blocked failureCounter
        this.gateway.setFailureDeltaTime(3000);
        this.gateway.setTime((new Date().getTime() / 1000) - 4);
        timeoutCall();
        assertEquals(1, this.gateway.getFailureCount());
        assertTrue("not yet failed over", this.gateway.isFailedOver());
        this.gateway.queryEmergency("test", "test");
        assertEquals(0, this.gateway.getFailureCount());
        assertTrue("not failed over", this.gateway.isFailedOver());
        timeoutCall();
        assertEquals(1, this.gateway.getFailureCount());
        assertTrue("not refailed over", this.gateway.isFailedOver());

        timeoutCall();
        assertEquals(2, this.gateway.getFailureCount());

        timeoutCall();
        assertFalse("refailed over", this.gateway.isFailedOver());
        assertEquals(0, this.gateway.getFailureCount());

        // Test blocked failureCounter
        timeoutCall();
        assertEquals(0, this.gateway.getFailureCount());
        timeoutCall();
        assertEquals(0, this.gateway.getFailureCount());
        timeoutCall();
        assertEquals(0, this.gateway.getFailureCount());
        assertFalse("refailed over", this.gateway.isFailedOver());

        verify();
    }

    private void timeoutCall() {
        try {
            this.gateway.queryEmergency("test", "test");
            fail("should have thrown a TimeoutException");
        } catch (TimeoutException e) {
            assertEquals("too long", e.getMessage());
        }
    }

    @Test
    public void testStates() {
        assertFalse("initial state", this.gateway.isFailedOver());
        assertIsPrimary("initial state");
        this.gateway.failover();
        assertIsSecondary("failed over");
        this.gateway.failover();
        assertIsPrimary("failed over again");
    }

    private void assertIsPrimary(String label) {
        assertFalse(label, this.gateway.isFailedOver());
        assertEquals(label, this.primaryTemplate, this.gateway.getTemplate());
    }

    private void assertIsSecondary(String label) {
        assertTrue(label, this.gateway.isFailedOver());
        assertEquals(label, this.secondaryTemplate, this.gateway.getTemplate());
    }
}
