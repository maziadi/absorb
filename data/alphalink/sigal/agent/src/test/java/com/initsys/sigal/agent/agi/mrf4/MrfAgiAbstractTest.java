package com.initsys.sigal.agent.agi.mrf4;

import static org.junit.Assert.fail;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

import com.initsys.sigal.agent.agi.SigalAgiAbstractTest;
import com.initsys.sigal.protocol.Sigal.ExdbQueryResponse;
import com.initsys.sigal.agent.agi.LimitReachedException;

public class MrfAgiAbstractTest extends SigalAgiAbstractTest {

    private ExdbQueryResponse createExForCount(Integer maxVnoCalls, Integer vnoCallCount, Integer maxCalls,
            Integer callCount, Integer maxInboundCalls, Integer inboundCalls,
            Integer maxOutboundCalls, Integer outboundCalls) {
        ExdbQueryResponse.Builder builder = ExdbQueryResponse.newBuilder()
                .setVersion(1);
        if (maxVnoCalls != null) {
            builder.setMaxVnoCalls(maxVnoCalls);
        }
        if (vnoCallCount != null) {
            builder.setVnoCallCount(vnoCallCount);
        }
        if (maxCalls != null) {
            builder.setMaxCalls(maxCalls);
        }
        if (callCount != null) {
            builder.setCallCount(callCount);
        }
        if (maxInboundCalls != null) {
            builder.setMaxInboundCalls(maxInboundCalls);
        }
        if (inboundCalls != null) {
            builder.setInboundCallCount(inboundCalls);
        }
        if (maxOutboundCalls != null) {
            builder.setMaxOutboundCalls(maxOutboundCalls);
        }
        if (outboundCalls != null) {
            builder.setOutboundCallCount(outboundCalls);
        }
        return builder.build();
    }

    public void assertTrueCounters(Integer maxVnoCalls, Integer vnoCallCount, Integer maxCalls, Integer callCount,
            Integer maxInboundCalls, Integer inboundCalls,
            Integer maxOutboundCalls, Integer outboundCalls, boolean inbound) {
        assertTrue(AbstractMrf4Agi.checkCounters(createExForCount(maxVnoCalls, vnoCallCount, maxCalls,
                callCount, maxInboundCalls, inboundCalls, maxOutboundCalls,
                outboundCalls), inbound));
    }

    public void assertExceptionCounters(Integer maxVnoCalls, Integer vnoCallCount, Integer maxCalls, Integer callCount,
        Integer maxInboundCalls, Integer inboundCalls,
        Integer maxOutboundCalls, Integer outboundCalls, boolean inbound) {
      try {
        AbstractMrf4Agi.checkCounters(createExForCount(maxVnoCalls, vnoCallCount, maxCalls,
                callCount, maxInboundCalls, inboundCalls, maxOutboundCalls,
                outboundCalls), inbound);
        fail("Should have thrown a LimitReachedException");
      } catch (Exception e) {
        assertTrue(e instanceof LimitReachedException);
      }
    }

    @Test
    public void testCounters() {
        assertTrueCounters(null, null, null, null, null, null, null, null, true);

        assertTrueCounters(1, null, null, null, null, null, null, null, true);
        assertTrueCounters(null, 1, null, null, null, null, null, null, true);
        assertExceptionCounters(1, 1, null, null, null, null, null, null, true);
        assertTrueCounters(1, 0, null, null, null, null, null, null, true);
        assertTrueCounters(2, 1, null, null, null, null, null, null, true);
        assertExceptionCounters(1, 2, null, null, null, null, null, null, true);
        assertExceptionCounters(1, 2, null, null, null, null, null, null, false);

        assertTrueCounters(null, null, 1, null, null, null, null, null, true);
        assertTrueCounters(null, null, null, 1, null, null, null, null, true);
        assertExceptionCounters(null, null, 1, 1, null, null, null, null, true);
        assertTrueCounters(null, null, 1, 0, null, null, null, null, true);
        assertExceptionCounters(null, null, 1, 2, null, null, null, null, true);
        assertExceptionCounters(null, null, 1, 2, null, null, null, null, false);

        assertTrueCounters(null, null, null, null, 1, null, null, null, true);
        assertTrueCounters(null, null, null, null, null, 1, null, null, true);
        assertExceptionCounters(null, null, null, null, 11, 11, null, null, true);
        assertTrueCounters(null, null, null, null, 9, 8, null, null, true);
        assertExceptionCounters(null, null, null, null, 19, 20, null, null, true);
        assertTrueCounters(null, null, null, null, 19, 20, null, null, false);

        assertTrueCounters(null, null, null, null, null, null, 100, null, true);
        assertTrueCounters(null, null, null, null, null, null, null, 167, true);
        assertTrueCounters(null, null, null, null, null, null, 143, 142, true);
        assertTrueCounters(null, null, null, null, null, null, 78, 32, true);
        assertTrueCounters(null, null, null, null, null, null, 2, 1893, true);
        assertExceptionCounters(null, null, null, null, null, null, 2, 1893, false);

        assertTrueCounters(11, 10, 11, 10, 11, 10, 11, 10, true);
        assertExceptionCounters(10, 11, 10, 10, 10, 10, 10, 10, true);
        assertExceptionCounters(10, 10, 10, 10, 10, 10, 10, 10, true);
        assertExceptionCounters(11, 10, 10, 11, 10, 10, 10, 10, true);
        assertExceptionCounters(11, 10, 10, 10, 10, 11, 10, 10, true);
        assertExceptionCounters(11, 10, 10, 11, 10, 10, 10, 10, true);
        assertExceptionCounters(11, 10, 10, 10, 10, 11, 10, 10, true);
        assertExceptionCounters(11, 10, 10, 10, 10, 10, 10, 11, true);
        assertExceptionCounters(11, 10, 10, 11, 10, 11, 10, 11, true);
        
        assertTrueCounters(11, 10, 11, 10, 11, 10, 10, 11, true);
        assertTrueCounters(11, 10, 11, 10, 10, 11, 11, 10, false);
    }
}
