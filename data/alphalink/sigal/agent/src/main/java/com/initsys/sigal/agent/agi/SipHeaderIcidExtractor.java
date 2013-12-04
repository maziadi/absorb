/**
 * 
 */
package com.initsys.sigal.agent.agi;

import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.asteriskjava.fastagi.AgiChannel;
import org.asteriskjava.fastagi.AgiException;

public class SipHeaderIcidExtractor {

    /** logger */
    private static final Logger log = LoggerFactory
            .getLogger(SipHeaderIcidExtractor.class);

    public String getIcid(AgiChannel channel) {
        String chargingVector;
        String icid;
        try {
            chargingVector = channel
                    .getVariable("SIP_HEADER(P-Charging-Vector)");
            if (StringUtils.isBlank(chargingVector)) {
                icid = channel.getVariable("ICID");
                if (StringUtils.isBlank(icid)) {
                    throw new IllegalStateException(
                            "P-Charging-Vector (or ICID variable) was not found");
                }
            } else {
                icid = chargingVector.replaceFirst(".*icid-value=([^;]+);.*",
                        "$1");
                if (StringUtils.isBlank(icid)) {
                    throw new IllegalArgumentException(
                            "Unable to extract icid from " + chargingVector);
                }

            }
            return icid;
        } catch (AgiException e) {
            log.error("  Unable to get ICID from channel", e);
            return null; // a new one will be created
        }
    }
}
