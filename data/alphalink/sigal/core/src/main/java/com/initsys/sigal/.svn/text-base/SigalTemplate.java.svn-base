package com.initsys.sigal;

import java.util.concurrent.TimeoutException;

import javax.jms.Destination;

import org.springframework.jms.core.MessageCreator;
import org.springframework.jms.support.converter.MessageConverter;

import com.google.protobuf.Message;

public interface SigalTemplate {
	public Message call(final Message query) throws TimeoutException;

	public MessageConverter getMessageConverter();

    public void send(Destination destination, MessageCreator messageCreator);
}
