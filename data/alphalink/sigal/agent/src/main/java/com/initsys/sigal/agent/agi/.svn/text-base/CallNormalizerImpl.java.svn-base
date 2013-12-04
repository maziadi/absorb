/**
 * 
 */
package com.initsys.sigal.agent.agi;

import java.util.regex.Pattern;
import java.util.regex.Matcher;

import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.initsys.sigal.numbers.PhoneNumberUtils;

public class CallNormalizerImpl implements CallNormalizer {

    /** logger */
    static final Logger log = LoggerFactory.getLogger(CallNormalizerImpl.class);

    enum NumberingPlan {

        /** Numérotation E.164 */
        E164,

        /** Numérotation E.164plus */
        E164PLUS,

        /** National sur 10 chiffres */
        NATIONAL,

        /** National sur 9 chiffres */
        NATIONAL9;
    }

    private static final String FRANCE_E164_PREFIX = "33";

    public void normalizeOutbound(CallContext callContext,
            String outboundNumberingPlan) {
      NumberingPlan callingNumberingPlan;
      NumberingPlan calledNumberingPlan;

      try {
        if("mix_nat_intl".equals(outboundNumberingPlan)) {
          callingNumberingPlan = extractNumberingPlan("national9");
          calledNumberingPlan = extractNumberingPlan("e164");
        } else {
          callingNumberingPlan = extractNumberingPlan(outboundNumberingPlan);
          calledNumberingPlan = extractNumberingPlan(outboundNumberingPlan);
        }

        // pour la gestion du +
        if(callingNumberingPlan.equals(extractNumberingPlan("e164"))) {
          callingNumberingPlan = extractNumberingPlan("e164plus");
        }

        checkCalledNumber(callContext);
        callContext.setEffectiveCalledNumber(normalizeNumber(callContext
              .getCalledNumber(), NumberingPlan.E164, calledNumberingPlan));
        callContext.setCallingNumber(StringUtils.stripStart(callContext
              .getCallingNumber(), "+"));
        callContext.setCallingIdentityNumber(StringUtils.stripStart(callContext
              .getCallingIdentityNumber(), "+"));

        if(callContext.getCallingNumber().equals("anonymous")) {
          callContext.setEffectiveCallingNumber("anonymous");
        } else {
          callContext.setEffectiveCallingNumber(normalizeNumber(callContext
                .getCallingNumber(), NumberingPlan.E164, callingNumberingPlan));
        }

        Pattern pattern = Pattern.compile("[a-zA-Z]");
        Matcher matcher = pattern.matcher(callContext.getCallingName());
        if (!matcher.find()) {
          callContext.setCallingName(callContext.getEffectiveCallingNumber());
        } 

        callContext.setEffectiveCallingIdentityNumber(
            normalizeNumber(callContext.getCallingIdentityNumber(),
              NumberingPlan.E164, callingNumberingPlan));
      } catch (CallException e) {
        throw new OutgoingAccountException(e.getMessage());
      }
    }

    /**
     * Everything is translated to E.164 according to the inbound numbering
     * plan.
     * 
     * @param callContext
     *            Normalized call context
     * @param inboundNumberingPlan
     * @param defaulCallingNumber
     *            Number used as default calling number if no calling number is
     *            present.
     */
    public void normalizeInbound(CallContext callContext,
            String inboundNumberingPlan, String defaulCallingNumber) {
      try {
        NumberingPlan numberingPlan = extractNumberingPlan(inboundNumberingPlan);

        checkCalledNumber(callContext);
        callContext.setEffectiveCalledNumber(normalizeNumber(callContext
              .getCalledNumber(), numberingPlan, NumberingPlan.E164));

        // TODO : cas a tester en test unitaire
        if (StringUtils.isBlank(callContext.getCallingNumber())) {
          if (StringUtils.isBlank(defaulCallingNumber)) {
            throw new IncomingAccountException("Calling number cannot be blank");
          }
          callContext.setEffectiveCallingNumber(defaulCallingNumber);
          callContext.setCallingNumber(defaulCallingNumber);
        } else {
          callContext.setCallingNumber(StringUtils.stripStart(callContext
                .getCallingNumber(), "+"));
          if ("anonymous".equals(callContext.getCallingNumber())) {
            callContext.setEffectiveCallingNumber(callContext
                .getCallingNumber());
          } else {
            callContext.setEffectiveCallingNumber(normalizeNumber(callContext
                  .getCallingNumber(), numberingPlan, NumberingPlan.E164));
          }

        }
      } catch (CallException e) {
          throw new IncomingAccountException(e.getMessage());
        }

    }

    private String normalizeNumber(String number, NumberingPlan srcPlan,
            NumberingPlan dstPlan) {
        number = StringUtils.stripStart(number, "+");
        if (dstPlan.equals(NumberingPlan.E164) || dstPlan.equals(NumberingPlan.E164PLUS)) {
            if (srcPlan.equals(NumberingPlan.NATIONAL)) {
                number = PhoneNumberUtils.nationalToE164(number,
                        FRANCE_E164_PREFIX);
            } else if (srcPlan.equals(NumberingPlan.NATIONAL9)) {
                number = national9ToE164(number, FRANCE_E164_PREFIX);
            } // else do nothing
            // TODO 1.9.1
            if (dstPlan.equals(NumberingPlan.E164PLUS)) {
              number = "+" + number;
            }
        } else if (dstPlan.equals(NumberingPlan.NATIONAL)) {
            if (srcPlan.equals(NumberingPlan.E164)) {
                number = PhoneNumberUtils.e164toNational(number,
                        FRANCE_E164_PREFIX);
            } else {
                throw new IllegalArgumentException("Cannot convert from "
                        + srcPlan + " to " + dstPlan);
            }

        } else { // national9
            if (srcPlan.equals(NumberingPlan.E164)) {
                number = e164toNational9(number, FRANCE_E164_PREFIX);
            } else {
                throw new IllegalArgumentException("Cannot convert from "
                        + srcPlan + " to " + dstPlan);
            }
        }
        return number;
    }

    private String e164toNational9(String number, String franceE164Prefix) {
        if (number.startsWith(franceE164Prefix)) {
            return number.substring(franceE164Prefix.length());
        } else {
            log.info("Could not convert '" + number + " to "
                    + NumberingPlan.NATIONAL9 + ": leaving unchanged");
            return number;
        }
    }

    private NumberingPlan extractNumberingPlan(String numberingPlan) {
        if ("national".equals(numberingPlan)) {
            return NumberingPlan.NATIONAL;
        } else if ("e164".equals(numberingPlan)) {
            return NumberingPlan.E164;
        } else if ("e164plus".equals(numberingPlan)) {
            return NumberingPlan.E164PLUS;
        } else if ("national9".equals(numberingPlan)) {
            return NumberingPlan.NATIONAL9;
        } else {
            throw new CallException("Unrecognized numbering plan: '"
                    + numberingPlan + "'");
        }

    }

    private void checkCalledNumber(CallContext callContext) {
        if (StringUtils.isBlank(callContext.getCalledNumber())) {
            throw new OutgoingAccountException("Called number cannot be blank");
        }
    }

    private String national9ToE164(String number, String prefix) {
        if (number.length() != 9) {
            throw new CallException("Cannot convert '" + number + "' to "
                    + NumberingPlan.NATIONAL9);
        }
        return prefix + number;
    }

}
