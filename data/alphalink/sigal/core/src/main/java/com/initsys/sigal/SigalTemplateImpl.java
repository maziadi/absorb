package com.initsys.sigal;

import java.util.Date;
import java.util.Random;
import java.util.concurrent.TimeoutException;

import javax.jms.DeliveryMode;
import javax.jms.Destination;
import javax.jms.ExceptionListener;
import javax.jms.JMSException;
import javax.jms.MessageConsumer;
import javax.jms.MessageProducer;
import javax.jms.Queue;
import javax.jms.Session;
import javax.jms.TemporaryTopic;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.asteriskjava.fastagi.command.SetExtensionCommand;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.jms.core.MessageCreator;
import org.springframework.jms.core.SessionCallback;
import org.springframework.jms.support.converter.MessageConverter;

import com.google.protobuf.Message;

/* TODO ou pas : renommer la classe en JmsTemplateImpl idem pour interface implementee */
public class SigalTemplateImpl implements SigalTemplate, ExceptionListener {

    /** logger */
    private static final Logger log = LoggerFactory.getLogger(SigalTemplateImpl.class);

    private JmsTemplate template;
    private Destination requestDestination;
    private Destination responseDestination;
    private Random random = new Random(System.currentTimeMillis());
    private Integer requestTimeout = 1000;

    public Integer getRequestTimeout() {
        return requestTimeout;
    }

    public void setRequestTimeout(Integer requestTimeout) {
        this.requestTimeout = requestTimeout;
    }

    public MessageConverter getMessageConverter() {
        return template.getMessageConverter();
    }

    private String createRandomString() {
        long randomLong = random.nextLong();
        return Long.toHexString(randomLong);
    }

    public Destination getRequestDestination() {
        return requestDestination;
    }

    /**
     * Lazily initializes a temporary topic as a destination,if none is present.
     * 
     * @return
     */
    public synchronized Destination getResponseDestination() {
        if (responseDestination == null) {
            this.responseDestination = (TemporaryTopic) getTemplate().execute(
                    new SessionCallback() {
                        public Object doInJms(Session session)
                                throws JMSException {
                            return session.createTemporaryTopic();
                        }
                    }, true);
        }
        return responseDestination;
    }

    public JmsTemplate getTemplate() {
        return template;
    }

    public void setRequestDestination(Destination destination) {
        this.requestDestination = destination;
    }

    public void setResponseDestination(Destination responseDestination) {
        this.responseDestination = responseDestination;
    }

    public void setTemplate(JmsTemplate template) {
        this.template = template;
    }

    
    
    public Message call(final Message query) throws TimeoutException {
        final String correlationId = createRandomString();
        javax.jms.Message response = (javax.jms.Message) getTemplate().execute(
                new SessionCallback() {
                    public Object doInJms(Session session) throws JMSException {                       
                        MessageProducer producer = session
                                .createProducer(getRequestDestination());
                        MessageConsumer consumer = session.createConsumer(
                                getResponseDestination(),
                                "JMSCorrelationID = '" + correlationId + "'");

                        javax.jms.Message msg = getTemplate()
                                .getMessageConverter()
                                .toMessage(query, session);
                        msg.setJMSCorrelationID(correlationId);
                        msg.setJMSReplyTo(getResponseDestination());
                        // TODO: ??? Use a parameter for time to live ?
                        // we need to do it ... jmsExpiration is useless only TTL is used
                        producer.setTimeToLive(getTemplate().getTimeToLive());
                        //msg.setJMSExpiration(new Date().getTime() + 300000);
                        producer.setDeliveryMode(DeliveryMode.NON_PERSISTENT);
                        producer.setPriority(5);
                        producer.send(msg);

                        return consumer.receive(getRequestTimeout());
                    }

                }, true);
        if (response == null) {
            throw new TimeoutException(
                    "No message was returned during allocated time");
        }

        try {
            Message responseMessage = (Message) getTemplate()
                    .getMessageConverter().fromMessage(response);
            if (log.isInfoEnabled()) {
                log.info("[" + query + "] returned [" + responseMessage + "]");
            }
            return responseMessage;
        } catch (JMSException e) {
            throw new RuntimeException(
                    "An error occured while accessing JMS message content", e);
        }
    }

    public void onException(JMSException exception) {
        log
                .error(
                        "JMS Connection has encountered an exception (dumping temporary topic)",
                        exception);
        setResponseDestination(null);
    }

    public void send(Destination destination, MessageCreator messageCreator) {
        getTemplate().send(destination, messageCreator);
    }
}
