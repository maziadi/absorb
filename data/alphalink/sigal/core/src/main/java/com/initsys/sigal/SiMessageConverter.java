package com.initsys.sigal;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

import javax.jms.BytesMessage;
import javax.jms.TextMessage;
import javax.jms.JMSException;
import javax.jms.Message;
import javax.jms.Session;

import org.apache.commons.lang.StringUtils;
import org.springframework.jms.support.converter.MessageConversionException;
import org.springframework.jms.support.converter.MessageConverter;
import org.springframework.util.ReflectionUtils;

import com.initsys.sigal.protocol.Si;

import com.googlecode.protobuf.format.JsonFormat;
import com.googlecode.protobuf.format.JsonFormat.ParseException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class SiMessageConverter implements MessageConverter {

	public static Class<?> messageTypeAsClass(String type) {
		String[] parts = StringUtils.splitByWholeSeparator(type, ".");
		StringBuffer buf = new StringBuffer(Si.class.getName()).append("$");

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

	public static Object parseMessageForType(String type, String data) {
		Class<?> messageClass = messageTypeAsClass(type);
    Object obj;

		if (messageClass == null) {
			throw new IllegalArgumentException("Unrecognized message type: '"
					+ type + "'");
		}
		try {
			Method m = ReflectionUtils.findMethod(messageClass, "newBuilder");

      // newBuilder ne prends pas de parametres contrairement a parseFrom
      //obj = m.invoke(null, new Object[] { data });
      obj = m.invoke(null, new Object[] { });

      JsonFormat.merge(data, ((com.google.protobuf.Message.Builder) obj));

      return ((com.google.protobuf.Message.Builder) obj).build();
		} catch (ParseException e) {
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

        String type = jmsMessage.getStringProperty("messageType");

        if (jmsMessage instanceof BytesMessage) {
          byte[] buf = new byte[(int) ((BytesMessage) jmsMessage)
            .getBodyLength()];

          ((BytesMessage) jmsMessage).readBytes(buf);

          return parseMessageForType(type, new String(buf));
        } else {
          throw new IllegalArgumentException(
              "Unable to convert from message type: "
              + jmsMessage.getClass().getName());
        }
  }

	public Message toMessage(Object obj, Session session) throws JMSException {
		com.google.protobuf.Message msg = (com.google.protobuf.Message) obj;
		TextMessage jmsMessage = session.createTextMessage();

    String type = StringUtils.join(
        StringUtils.splitByCharacterTypeCamelCase(msg
          .getDescriptorForType().getName()), ".").toUpperCase();
    jmsMessage.setStringProperty("messageType", type);
    jmsMessage
      .setText(JsonFormat.printToString(msg));

		return jmsMessage;
	}
}
