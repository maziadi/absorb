package com.initsys.sigal.agent;

import static junit.framework.Assert.assertEquals;
import static junit.framework.Assert.assertFalse;
import static junit.framework.Assert.assertTrue;
import static junit.framework.Assert.fail;
import static org.easymock.classextension.EasyMock.createStrictMock;
import static org.easymock.classextension.EasyMock.expect;
import static org.easymock.classextension.EasyMock.isA;

import java.util.concurrent.TimeoutException;

import javax.jms.Queue;
import javax.jms.Topic;

import org.easymock.classextension.EasyMock;
import org.junit.Before;
import org.junit.Test;

import com.initsys.sigal.SigalTemplate;
import com.initsys.sigal.agent.SiAgentMessagingGateway;
import com.initsys.sigal.protocol.Si.SviRioQueryRequest;
import com.initsys.sigal.protocol.Si.SviRioQueryResponse;
import com.initsys.sigal.protocol.Si.SmsSendRequest;
import com.initsys.sigal.protocol.Si.SmsServerAck;
import com.initsys.sigal.protocol.Si.SmsData;
import com.google.protobuf.Message;

public class SiAgentMessagingGatewayTest {

    private SiAgentTemplate sviRioTemplate;
    private SigalTemplate siTemplate;

    @Before
    public void setUp() {
        this.siTemplate = createStrictMock(SigalTemplate.class);
        this.sviRioTemplate = new SiAgentMessagingGateway();
        ((SiAgentMessagingGateway) sviRioTemplate).setSiTemplate(siTemplate);
        ((SiAgentMessagingGateway) sviRioTemplate).setSmsStringNoDate("Votre contrat n'est pas soumis à un engagement.");
        ((SiAgentMessagingGateway) sviRioTemplate).setSmsStringDate("Votre engagement prendra fin le ");
        ((SiAgentMessagingGateway) sviRioTemplate).setSmsStringRio(" Votre RIO est : ");
    }

    private void replay() {
        EasyMock.replay(this.siTemplate);
    }

    private void verify() {
        EasyMock.verify(this.siTemplate);
    }

    @Test
    public void testSendRioBySmsWithNoDate() throws TimeoutException {
        SviRioQueryResponse response = SviRioQueryResponse.newBuilder()
            .setMsisdn("toto").setRio("toto").setDate("").build();
        SmsServerAck ack = SmsServerAck.newBuilder().setStatus(200).setMessage("OK").build();
        SmsData data = SmsData.newBuilder().setText("Votre contrat n'est pas soumis à un engagement."
                + " Votre RIO est : " + "toto" + ".").setMsisdn("toto").build();
        SmsSendRequest request = SmsSendRequest.newBuilder().setUri("/xms")
            .setAction("create").setData(data).build();
        expect(siTemplate.call(request)).andReturn(ack);
        replay();
        sviRioTemplate.sendRioBySms(response);
        verify();
    }

    @Test
    public void testSendRioBySmsWithDate() throws TimeoutException {
        SviRioQueryResponse response = SviRioQueryResponse.newBuilder()
            .setMsisdn("toto").setRio("toto").setDate("1970-01-01T00:00:00+00:00").build();
        SmsServerAck ack = SmsServerAck.newBuilder().setStatus(200).setMessage("OK").build();
        SmsData data = SmsData.newBuilder().setText("Votre engagement prendra fin le "
                + "01/01/1970" + "."
                + " Votre RIO est : " + "toto" + ".").setMsisdn("toto").build();
        SmsSendRequest request = SmsSendRequest.newBuilder().setUri("/xms")
            .setAction("create").setData(data).build();
        expect(siTemplate.call(request)).andReturn(ack);
        replay();
        sviRioTemplate.sendRioBySms(response);
        verify();
    }
}
