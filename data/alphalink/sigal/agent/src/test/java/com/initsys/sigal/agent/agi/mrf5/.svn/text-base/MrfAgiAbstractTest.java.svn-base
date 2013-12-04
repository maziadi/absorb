package com.initsys.sigal.agent.agi.mrf5;

import static org.easymock.EasyMock.expect;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import java.util.List;
import java.util.concurrent.TimeoutException;

import org.asteriskjava.fastagi.AgiException;
import org.junit.Test;

import com.initsys.sigal.agent.agi.SigalAgiAbstractTest;
import com.initsys.sigal.agent.agi.mrf4.AbstractMrf4Agi;
import com.initsys.sigal.protocol.Sigal.EmdbQueryResponse;
import com.initsys.sigal.protocol.Sigal.LidbQueryResponse;

public abstract class MrfAgiAbstractTest<A extends AbstractMrf5Agi> extends
        SigalAgiAbstractTest<A> {

    @Override
    public void setUp() throws Exception {
        super.setUp();
        String[] gwChannelName = new String[] {"GW"};
        getAgi().setGwChannelName(gwChannelName);
        getAgi().setOutEstablishmentTimeout(122);
        getAgi().setInEstablishmentTimeout(123);
    }

    protected void expectEmergencyQuery(String number, String inseeCode,
            List<String> translation) throws TimeoutException {
        EmdbQueryResponse.Builder response = EmdbQueryResponse.newBuilder();

        response.setVersion(1);
        response.setNumber(number);
        response.setInseeCode(inseeCode);
        response.addAllTranslation(translation);
        expect(getTemplate().queryEmergency(number, inseeCode)).andReturn(
                response.build());
    }

    protected void expectSetXRedirectingNumber(String number)
            throws AgiException {
        expect(
                getChannel().exec("SipAddHeader",
                        "X-RedirectingNumber: " + number)).andReturn(0);
    }

    public void expectHangup() throws AgiException {
        getChannel().hangup();
    }

    private LidbQueryResponse createLiForCount(Integer maxVnoCalls, Integer vnoCallCount, Integer maxCalls,
            Integer callCount, Integer maxInboundCalls, Integer inboundCalls,
            Integer maxOutboundCalls, Integer outboundCalls) {
        LidbQueryResponse.Builder builder = LidbQueryResponse.newBuilder()
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
        assertTrue(AbstractMrf5Agi.checkCounters(createLiForCount(maxVnoCalls, vnoCallCount, maxCalls,
                callCount, maxInboundCalls, inboundCalls, maxOutboundCalls,
                outboundCalls), inbound));
    }

    public void assertFalseCounters(Integer maxVnoCalls, Integer vnoCallCount, Integer maxCalls, Integer callCount,
            Integer maxInboundCalls, Integer inboundCalls,
            Integer maxOutboundCalls, Integer outboundCalls, boolean inbound) {
        assertFalse(AbstractMrf5Agi.checkCounters(createLiForCount(maxVnoCalls, vnoCallCount, maxCalls,
                callCount, maxInboundCalls, inboundCalls, maxOutboundCalls,
                outboundCalls), inbound));
    }

    @Test
    public void testCounters() {
        assertTrueCounters(null, null, null, null, null, null, null, null, true);

        assertTrueCounters(1, null, null, null, null, null, null, null, true);
        assertTrueCounters(null, 1, null, null, null, null, null, null, true);
        assertFalseCounters(1, 1, null, null, null, null, null, null, true);
        assertTrueCounters(1, 0, null, null, null, null, null, null, true);
        assertTrueCounters(2, 1, null, null, null, null, null, null, true);
        assertFalseCounters(1, 2, null, null, null, null, null, null, true);
        assertFalseCounters(1, 2, null, null, null, null, null, null, false);

        assertTrueCounters(null, null, 1, null, null, null, null, null, true);
        assertTrueCounters(null, null, null, 1, null, null, null, null, true);
        assertFalseCounters(null, null, 1, 1, null, null, null, null, true);
        assertTrueCounters(null, null, 1, 0, null, null, null, null, true);
        assertFalseCounters(null, null, 1, 2, null, null, null, null, true);
        assertFalseCounters(null, null, 1, 2, null, null, null, null, false);

        assertTrueCounters(null, null, null, null, 1, null, null, null, true);
        assertTrueCounters(null, null, null, null, null, 1, null, null, true);
        assertFalseCounters(null, null, null, null, 11, 11, null, null, true);
        assertTrueCounters(null, null, null, null, 9, 8, null, null, true);
        assertFalseCounters(null, null, null, null, 19, 20, null, null, true);
        assertTrueCounters(null, null, null, null, 19, 20, null, null, false);

        assertTrueCounters(null, null, null, null, null, null, 100, null, true);
        assertTrueCounters(null, null, null, null, null, null, null, 167, true);
        assertTrueCounters(null, null, null, null, null, null, 143, 142, true);
        assertTrueCounters(null, null, null, null, null, null, 78, 32, true);
        assertTrueCounters(null, null, null, null, null, null, 2, 1893, true);
        assertFalseCounters(null, null, null, null, null, null, 2, 1893, false);

        assertTrueCounters(11, 10, 11, 10, 11, 10, 11, 10, true);
        assertFalseCounters(10, 11, 10, 10, 10, 10, 10, 10, true);
        assertFalseCounters(10, 10, 10, 10, 10, 10, 10, 10, true);
        assertFalseCounters(11, 10, 10, 11, 10, 10, 10, 10, true);
        assertFalseCounters(11, 10, 10, 10, 10, 11, 10, 10, true);
        assertFalseCounters(11, 10, 10, 11, 10, 10, 10, 10, true);
        assertFalseCounters(11, 10, 10, 10, 10, 11, 10, 10, true);
        assertFalseCounters(11, 10, 10, 10, 10, 10, 10, 11, true);
        assertFalseCounters(11, 10, 10, 11, 10, 11, 10, 11, true);
        
        assertTrueCounters(11, 10, 11, 10, 11, 10, 10, 11, true);
        assertTrueCounters(11, 10, 11, 10, 10, 11, 11, 10, false);
    }

}
