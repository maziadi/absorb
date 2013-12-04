package com.initsys.sigal.agent.agi;

import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.asteriskjava.fastagi.AgiRequest;
import org.asteriskjava.fastagi.AgiScript;
import org.asteriskjava.fastagi.AgiChannel;
import org.asteriskjava.fastagi.MappingStrategy;

public class DebugSimpleMappingStrategy implements MappingStrategy {
	/** logger */
	private static final Logger log = LoggerFactory
			.getLogger(DebugSimpleMappingStrategy.class);

	private Map<String, AgiScript> mappings;

	/**
	 * Set the "path to AgiScript" mapping.
	 * <p>
	 * Use the path (for example <code>hello.agi</code>) as key and your
	 * AgiScript (for example <code>new HelloAgiScript()</code>) as value of
	 * this map.
	 * 
	 * @param mappings
	 *            the path to AgiScript mapping.
	 */
	public void setMappings(Map<String, AgiScript> mappings) {
		this.mappings = mappings;
	}

	public AgiScript determineScript(AgiRequest request, AgiChannel channel) {
		log.info("Mappings:" + this.mappings);
		log.info("Script:" + request.getScript());
		if (mappings == null) {
			return null;
		}

		return mappings.get(request.getScript());
	}
}
