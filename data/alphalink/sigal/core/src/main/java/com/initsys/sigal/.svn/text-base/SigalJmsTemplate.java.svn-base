package com.initsys.sigal;

import javax.jms.Connection;
import javax.jms.ExceptionListener;
import javax.jms.JMSException;

import org.springframework.jms.core.JmsTemplate;

public class SigalJmsTemplate extends JmsTemplate {

	private ExceptionListener exceptionListener;

	public ExceptionListener getExceptionListener() {
		return exceptionListener;
	}

	public void setExceptionListener(ExceptionListener exceptionListener) {
		this.exceptionListener = exceptionListener;
	}

	/**
	 * Override the method to set the current templates
	 * {@link ExceptionListener} on the create connection. If property
	 * <code>exceptionListener</code> is null, nothing happens.
	 */
	@Override
	protected Connection createConnection() throws JMSException {
		Connection connection = super.createConnection();
		if (connection != null && getExceptionListener() == null) {
			connection.setExceptionListener(getExceptionListener());
		}
		return connection;
	}
}
