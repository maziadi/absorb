package com.initsys.sigal;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

import javax.jms.BytesMessage;
import javax.jms.JMSException;
import javax.jms.Message;
import javax.jms.Session;

import org.apache.commons.lang.StringUtils;
import org.springframework.jms.support.converter.MessageConversionException;
import org.springframework.jms.support.converter.MessageConverter;
import org.springframework.util.ReflectionUtils;

import com.initsys.sigal.protocol.Sigal;

public class SigalMessageConverter implements MessageConverter {

	public static Class<?> messageTypeAsClass(String type) {
		String[] parts = StringUtils.splitByWholeSeparator(type, ".");
		StringBuffer buf = new StringBuffer(Sigal.class.getName()).append("$");

		for (int i = 0; i < parts.length; i++) {
			buf.append(StringUtils.capitalize(parts[i].toLowerCase()));
		}
		try {
			return Thread.currentThread().getContextClassLoader().loadClass(
					buf.toString());
		} catch (ClassNotFoundException e) {
			throw new IllegalArgumentException(
					"Unable to find message classe for message type : '" + type
							+ "'", e);
		}
	}

	public static Object parseMessageForType(String type, byte[] data) {
		Class<?> messageClass = messageTypeAsClass(type);

		if (messageClass == null) {
			throw new IllegalArgumentException("Unrecognized message type: '"
					+ type + "'");
		}
		try {
			Method m = ReflectionUtils.findMethod(messageClass, "parseFrom",
					new Class[] { Class.forName("[B") });

			return m.invoke(null, new Object[] { data });
		} catch (ClassNotFoundException e) {
			throw new RuntimeException("Should not have happened", e);
		} catch (IllegalArgumentException e) {
			throw new RuntimeException("Should not have happened", e);
		} catch (IllegalAccessException e) {
			throw new RuntimeException(e);
		} catch (InvocationTargetException e) {
			throw new RuntimeException(e.getCause());
		}
	}

	public Object fromMessage(Message jmsMessage) throws JMSException,
			MessageConversionException {
		if (jmsMessage instanceof BytesMessage) {
			String type = jmsMessage.getStringProperty("messageType");
			byte[] buf = new byte[(int) ((BytesMessage) jmsMessage)
					.getBodyLength()];

			((BytesMessage) jmsMessage).readBytes(buf);

			return parseMessageForType(type, buf);
		} else {
			throw new IllegalArgumentException(
					"Unable to convert from message type: "
							+ jmsMessage.getClass().getName());
		}
	}

	public Message toMessage(Object obj, Session session) throws JMSException,
			MessageConversionException {
		com.google.protobuf.Message msg = (com.google.protobuf.Message) obj;
		BytesMessage jmsMessage = session.createBytesMessage();

		String type = StringUtils.join(
				StringUtils.splitByCharacterTypeCamelCase(msg
						.getDescriptorForType().getName()), ".").toUpperCase();
		jmsMessage.setStringProperty("messageType", type);
		jmsMessage
				.writeBytes(((com.google.protobuf.Message) msg).toByteArray());

		return jmsMessage;
	}
}
