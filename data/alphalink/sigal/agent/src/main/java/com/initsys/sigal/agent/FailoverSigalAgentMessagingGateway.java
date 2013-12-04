package com.initsys.sigal.agent;

import java.util.Date;
import java.util.concurrent.TimeoutException;

import javax.jms.DeliveryMode;
import javax.jms.JMSException;
import javax.jms.Queue;
import javax.jms.Session;
import javax.jms.Topic;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.jms.JmsException;
import org.springframework.jms.core.MessageCreator;

import com.initsys.sigal.SigalTemplate;

import com.google.protobuf.Message;
import com.initsys.sigal.protocol.Sigal.Cdr;
import com.initsys.sigal.SigalTemplateImpl;
import com.initsys.sigal.protocol.Sigal.EmdbQueryRequest;
import com.initsys.sigal.protocol.Sigal.EmdbQueryResponse;
import com.initsys.sigal.protocol.Sigal.ExdbQueryRequest;
import com.initsys.sigal.protocol.Sigal.ExdbQueryResponse;
import com.initsys.sigal.protocol.Sigal.LidbQueryRequest;
import com.initsys.sigal.protocol.Sigal.LidbQueryResponse;
import com.initsys.sigal.protocol.Sigal.MlidbQueryRequest;
import com.initsys.sigal.protocol.Sigal.MlidbQueryResponse;
import com.initsys.sigal.protocol.Sigal.NpdbQueryRequest;
import com.initsys.sigal.protocol.Sigal.NpdbQueryResponse;

public class FailoverSigalAgentMessagingGateway implements SigalAgentTemplate {

    SigalTemplate primaryTemplate;

    SigalTemplate secondaryTemplate;

    private int failureCount = 0;

    private int maxFailureCount;

    private boolean isFailedOver = false;

    private int failureDeltaTime;

    private long time = 0L;

    /** logger */
    private static final Log log = LogFactory
            .getLog(FailoverSigalAgentMessagingGateway.class);

    private Queue cdrQueueDestination;

    private Topic cdrTopicDestination;

    private Message call(Message build) throws TimeoutException {
        try {
            Message message = getTemplate().call(build);

            resetFailureCount();
            return message;
        } catch (TimeoutException e) {
            handleFailure(1);
            throw e;
        } catch (RuntimeException e) {
            handleFailure(1);
            throw e;
        } catch (Exception e) {
            handleFailure(1);
            throw new RuntimeException(
                    "Exception caught by the failover messaging gateway (see cause)",
                    e);
        }
    }

    public void failover() {
        String msg;
        if (isFailedOver()) {
            msg = "secondary to primary";
        } else {
            msg = "primary to secondary";
        }
        log.error("FAILING OVER from " + msg);
        resetFailureCount();
        setFailedOver(isFailedOver() ? false : true);
        //enregistrer le timestamp après le failover
        this.time = new Date().getTime(); 
    }

    public Queue getCdrQueueDestination() {
        return cdrQueueDestination;
    }

    public Topic getCdrTopicDestination() {
        return cdrTopicDestination;
    }

    public int getFailureCount() {
        return failureCount;
    }

    public int getMaxFailureCount() {
        return maxFailureCount;
    }

    public int getFailureDeltaTime() {
        return failureDeltaTime;
    }

    public SigalTemplate getPrimaryTemplate() {
        return primaryTemplate;
    }

    public SigalTemplate getSecondaryTemplate() {
        return secondaryTemplate;
    }

    SigalTemplate getTemplate() {
        return isFailedOver() ? getSecondaryTemplate() : getPrimaryTemplate();
    }

    public long getTime() {
      return time;
    }

    public boolean isFailedOver() {
        return isFailedOver;
    }

    /**
     * @see SigalAgentTemplate#queryLineInfoByNumber(String)
     */
    public EmdbQueryResponse queryEmergency(String phoneNumber, String inseeCode)
            throws TimeoutException {

        Message response = call(EmdbQueryRequest.newBuilder().setVersion(1)
                .setNumber(phoneNumber).setInseeCode(inseeCode).build());
        if (!(response instanceof EmdbQueryResponse)) {
            throw new RuntimeException(
                    "Response to EMDB QUERY should be EMDB RESPONSE not "
                            + response);
        }
        return (EmdbQueryResponse) response;
    }

    public ExdbQueryResponse queryIntercoByAccountCode(String accountCode)
            throws TimeoutException {
        Message response = call(ExdbQueryRequest.newBuilder().setVersion(1)
                .setAccountCode(accountCode).build());

        if (!(response instanceof ExdbQueryResponse)) {
            throw new RuntimeException(
                    "Response to EXDB QUERY should be EXDB RESPONSE not "
                            + response);
        }
        return (ExdbQueryResponse) response;
    }

    /**
     * @see SigalAgentTemplate#queryLineInfoByNumber(String)
     */
    public LidbQueryResponse queryLineInfoByNumber(String phoneNumber)
            throws TimeoutException {
        Message response = call(LidbQueryRequest.newBuilder().setVersion(1)
                .setNumber(phoneNumber).build());
        if (!(response instanceof LidbQueryResponse)) {
            throw new RuntimeException(
                    "Response to LIDB QUERY should be LIDB RESPONSE not "
                            + response);
        }
        return (LidbQueryResponse) response;
    }

    /**
     * @see SigalAgentTemplate#queryLineInfoByAccountCode(String)
     */
    public LidbQueryResponse queryLineInfoByAccountCode(String accountCode)
            throws TimeoutException {
        Message response = call(LidbQueryRequest.newBuilder().setVersion(1)
                .setAccountCode(accountCode).build());

        if (!(response instanceof LidbQueryResponse)) {
            throw new RuntimeException(
                    "Response to LIDB QUERY should be LIDB RESPONSE not "
                            + response);
        }
        return (LidbQueryResponse) response;
    }

    /**
     * @see SigalAgentTemplate#queryMobileLineInfoByMsisdn(String)
     */
    public MlidbQueryResponse queryMobileLineInfoByMsisdn(String phoneNumber)
            throws TimeoutException {
        Message response = call(MlidbQueryRequest.newBuilder().setVersion(1)
                .setMsisdn(phoneNumber).build());
        if (!(response instanceof MlidbQueryResponse)) {
            throw new RuntimeException(
                    "Response to MLIDB QUERY should be MLIDB RESPONSE not "
                            + response);
        }
        return (MlidbQueryResponse) response;
    }

    /**
     * @see SigalAgentTemplate#queryPorted(String)
     */
    public NpdbQueryResponse queryPorted(final String phoneNumber)
            throws TimeoutException {
        Message response = call(NpdbQueryRequest.newBuilder().setVersion(1)
                .setNumber(phoneNumber).build());

        if (!(response instanceof NpdbQueryResponse)) {
            throw new RuntimeException(
                    "Response to NPDB QUERY should be NPDB RESPONSE not "
                            + response);
        }
        return (NpdbQueryResponse) response;
    }

    private void resetFailureCount() {
        log.debug("Reset failure count and failover (" + isFailedOver() + ")");
        this.failureCount = 0;
    }

    public void sendCdrMessage(final Cdr cdrMessage) {
        if (log.isInfoEnabled()) {
            log.info("Sending: "
                    + cdrMessage.toString().trim().replaceAll("\n *", ", ")
                            .replaceAll("\\{,", "{").replaceAll(", }", "}")
                            .replaceAll("version: 1, ", ""));
        }
        try {
            getTemplate().send(getCdrQueueDestination(), new MessageCreator() {
                public javax.jms.Message createMessage(Session session)
                        throws JMSException {
                    javax.jms.Message message = getTemplate()
                            .getMessageConverter().toMessage(cdrMessage,
                                    session);
                    message.setJMSDeliveryMode(DeliveryMode.PERSISTENT);
                    return message;
                }

            });
            getTemplate().send(getCdrTopicDestination(), new MessageCreator() {
                public javax.jms.Message createMessage(Session session)
                        throws JMSException {
                    javax.jms.Message message = getTemplate()
                            .getMessageConverter().toMessage(cdrMessage,
                                    session);
                    message.setJMSDeliveryMode(DeliveryMode.NON_PERSISTENT);

                    return message;
                }
            });
            // TODO : pourquoi pas de resetFailureCount() ???
        } catch (RuntimeException e) {
            handleFailure(3);
            throw e;
        } catch (Exception e) {
            handleFailure(3);
            throw new RuntimeException(
                    "Exception caught by the failover messaging gateway (see cause)",
                    e);
        }

    }

    private void handleFailure(int incrementValue) {
      if ((int) ((new Date().getTime() - time) / 1000) > getFailureDeltaTime() / 1000) {
        this.failureCount += incrementValue;
        log.debug("Increment failure to " + this.failureCount + " and failover (" + isFailedOver() + ")");
      } else {
        log.debug("FailureCount blocked for " + getFailureDeltaTime() / 1000  + "s");
      }
      if (this.failureCount >= getMaxFailureCount()) {
        failover();
      }
    }

    public void setCdrQueueDestination(Queue primaryCdrQueueDestination) {
        this.cdrQueueDestination = primaryCdrQueueDestination;
    }

    public void setCdrTopicDestination(Topic primaryCdrTopicDestination) {
        this.cdrTopicDestination = primaryCdrTopicDestination;
    }

    void setFailedOver(boolean isFailedOver) {
        this.isFailedOver = isFailedOver;
    }

    public void setMaxFailureCount(int maxFailureCount) {
        this.maxFailureCount = maxFailureCount;
    }
    
    public void setFailureDeltaTime(int failureDeltaTime) {
        this.failureDeltaTime = failureDeltaTime;
    }

    public void setPrimaryTemplate(SigalTemplate primaryTemplate) {
        this.primaryTemplate = primaryTemplate;
    }

    public void setSecondaryTemplate(SigalTemplate secondaryTemplate) {
        this.secondaryTemplate = secondaryTemplate;
    }

    public void setTime(long time) {
        this.time = time;
    }

}
