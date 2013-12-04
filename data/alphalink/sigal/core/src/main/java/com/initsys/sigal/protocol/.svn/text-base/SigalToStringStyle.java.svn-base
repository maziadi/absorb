package com.initsys.sigal.protocol;

import org.apache.commons.lang.builder.StandardToStringStyle;

/**
 * Style for SIGAL queries and responses.
 */
public class SigalToStringStyle extends StandardToStringStyle {

	public static final SigalToStringStyle STYLE = new SigalToStringStyle(false);

	public static final SigalToStringStyle MULTI_LINE_STYLE = new SigalToStringStyle(
			true);

	private SigalToStringStyle(boolean multiline) {
		setUseClassName(false);
		setUseIdentityHashCode(false);
		setFieldSeparator(multiline ? ",\n" : ", ");
		setNullText("<null>");
		if (multiline) {
			setContentStart("");
			setContentEnd("");
		}
	}

}
