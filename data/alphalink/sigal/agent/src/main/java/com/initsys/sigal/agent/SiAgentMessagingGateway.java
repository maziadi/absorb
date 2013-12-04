package com.initsys.sigal.agent;

import java.util.concurrent.TimeoutException;
import java.text.ParseException;

import javax.jms.DeliveryMode;
import javax.jms.JMSException;
import javax.jms.Queue;
import javax.jms.Session;
import javax.jms.Topic;

import java.text.SimpleDateFormat;
import java.util.Locale;
import java.util.Date;

import static org.apache.commons.lang.StringUtils.isBlank;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.jms.JmsException;
import org.springframework.jms.core.MessageCreator;

import com.initsys.sigal.SigalTemplate;

import com.google.protobuf.Message;

import com.initsys.sigal.protocol.Si.SviRioQueryRequest;
import com.initsys.sigal.protocol.Si.SviRioQueryResponse;
import com.initsys.sigal.protocol.Si.SmsSendRequest;
import com.initsys.sigal.protocol.Si.SmsServerAck;
import com.initsys.sigal.protocol.Si.SmsData;

public class SiAgentMessagingGateway implements SiAgentTemplate {

    private SigalTemplate siTemplate;

    /** String used when sending sms for account with no end date */
    private String smsStringNoDate;

    /** String used when sending sms for account with end date */
    private String smsStringDate;

    /** String used when sending containing RIO */
    private String smsStringRio;

    /** logger */
    private static final Log log = LogFactory
        .getLog(SiAgentMessagingGateway.class);

    public SigalTemplate getSiTemplate() {
        return siTemplate;
    }

    public void setSiTemplate(SigalTemplate siTemplate) {
        this.siTemplate = siTemplate;
    }

    public String getSmsStringNoDate() {
        return smsStringNoDate;
    }

    public void setSmsStringNoDate(String smsStringNoDate) {
        this.smsStringNoDate = smsStringNoDate;
    }

    public String getSmsStringDate() {
        return smsStringDate;
    }

    public void setSmsStringDate(String smsStringDate) {
        this.smsStringDate = smsStringDate;
    }

    public String getSmsStringRio() {
        return smsStringRio;
    }

    public void setSmsStringRio(String smsStringRio) {
        this.smsStringRio = smsStringRio;
    }

    private Message call(Message build) throws TimeoutException {
        try {
            Message message = getSiTemplate().call(build);
            return message;
        } catch (TimeoutException e) {
            throw e;
        } catch (Exception e) {
            throw new RuntimeException(
                    "Exception caught by the si messaging gateway (see cause)",
                    e);
        }
    }

    /**
     * @see SiAgentTemplate#querySviRioByNumber(String)
     */
    public SviRioQueryResponse querySviRioByNumber(String phoneNumber)
        throws TimeoutException {

        Message response = call(SviRioQueryRequest.newBuilder()
                .setMsisdn(phoneNumber).build());
        if (!(response instanceof SviRioQueryResponse)) {
            throw new RuntimeException(
                    "Response to SVI.RIO QUERY should be SVI.RIO RESPONSE not "
                    + response);
        }
        return (SviRioQueryResponse) response;
    }

    public SmsServerAck sendRioBySms(SviRioQueryResponse sviRioResponse)
        throws TimeoutException {

        String msg, theDate = null;
        if (isBlank(sviRioResponse.getDate())) {
            msg = getSmsStringNoDate();
        } else {
            try {
                SimpleDateFormat ISO8601DATEFORMAT = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ", Locale.FRANCE);
                SimpleDateFormat msgFormat = new SimpleDateFormat("dd/MM/yyyy", Locale.FRANCE);
                theDate = msgFormat.format(ISO8601DATEFORMAT
                        .parse(sviRioResponse.getDate().replaceAll(":00$", "00")));
            } catch (ParseException e) {
                log.error("ParseException occured");
            }
            msg = getSmsStringDate() + theDate + ".";
        }

        msg = msg.concat(getSmsStringRio() + sviRioResponse.getRio() + ".");

        Message response = call(SmsSendRequest.newBuilder()
                .setUri("/xms").setAction("create")
                .setData(SmsData.newBuilder().setMsisdn(sviRioResponse.getMsisdn())
                    .setText(msg).build()).build());
        if (!(response instanceof SmsServerAck)) {
            throw new RuntimeException(
                    "Response to SEND SMS QUERY should be SMS SERVER ACK not "
                    + response);
        }
        return (SmsServerAck) response;
    }
}
