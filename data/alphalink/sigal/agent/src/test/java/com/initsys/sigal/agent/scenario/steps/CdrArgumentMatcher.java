/**
 * 
 */
package com.initsys.sigal.agent.scenario.steps;

import org.easymock.IArgumentMatcher;
import org.easymock.internal.matchers.Any;
import org.easymock.internal.matchers.Equals;

import com.initsys.sigal.protocol.Sigal.Cdr;
import com.initsys.sigal.vno.VnoConstants;

class CdrArgumentMatcher implements IArgumentMatcher {

    private IArgumentMatcher convert(final String val) {
        if (val == null || "<null>".equals(val)) {
            return null;
        } else if ("<any>".equals(val)) {
            return Any.ANY;
        }
        return new Equals(val);
    }

    private IArgumentMatcher integerConvert(final String val) {
        if (val == null || "<null>".equals(val)) {
            return null;
        } else if ("<any>".equals(val)) {
            return Any.ANY;
        }
        return new Equals(Integer.parseInt(val));
    }

    CdrArgumentMatcher(boolean complete, String icid, String endCause,
        String billableDuration, String callingNetwork, String callingAccountCode,
        String callingNumber, String callingIdentityNumber, String presentation,
        String callingName, String callingCarrierCode, String calledNetwork,
        String calledAccountCode, String calledNumber, String calledName,
        String calledCarrierCode) {
      this.complete = new Equals(complete);
      this.icid = convert(icid);
      this.endCause = convert(endCause.replace("_", "/"));
      this.billableDuration = integerConvert(billableDuration);
      this.callingNetwork = convert(callingNetwork);
      this.callingAccountCode = convert(callingAccountCode);
      this.callingNumber = convert(callingNumber);
      this.callingIdentityNumber = convert(callingIdentityNumber);
      this.callingPresentation = convert(presentation);
      this.callingName = convert(callingName);
      this.callingCarrierCode = convert(callingCarrierCode);
      this.calledNetwork = convert(calledNetwork);
      this.calledAccountCode = convert(calledAccountCode);
      this.calledNumber = convert(calledNumber);
      this.calledName = convert(calledName);
      this.calledCarrierCode = convert(calledCarrierCode);
    }

    CdrArgumentMatcher(boolean complete, String icid, String callingNetwork,
        String callingAccountCode, String callingNumber,
        String callingIdentityNumber, String presentation,
        String callingName, String callingCarrierCode,
        String calledNetwork, String calledAccountCode, String calledNumber,
        String calledName, String calledCarrierCode) {
      this(complete, icid, "<any>", "<any>", callingNetwork,
          callingAccountCode, callingNumber,
          callingIdentityNumber, presentation,
          callingName, callingCarrierCode,
          calledNetwork, calledAccountCode, calledNumber,
          calledName, calledCarrierCode);
    }

    CdrArgumentMatcher(boolean complete, String icid, String carrierCode,
        String callingNetwork, String callingAccountCode,
        String callingNumber, String callingIdentityNumber,
        String presentation, String callingName, String calledNetwork,
        String calledAccountCode, String calledNumber, String calledName) {
      this(complete, icid, "<any>", "<any>", callingNetwork, callingAccountCode,
          callingNumber, callingIdentityNumber, presentation, callingName, 
          carrierCode, calledNetwork, calledAccountCode, calledNumber,
          calledName, carrierCode);
    }

    CdrArgumentMatcher(boolean complete, String icid, String endCause,
        String billableDuration) {
      this(complete, icid, endCause, billableDuration,
          "<any>", "<any>", "<any>", "<any>", "<any>", "<any>", 
          "<any>", "<any>", "<any>", "<any>", "<any>", "<any>");
    }

    public boolean matches(Object actual) {
        if (!(actual instanceof Cdr)) {
            return false;
        }
        Cdr cdr = (Cdr) actual;

        if (!this.complete.matches(cdr.getComplete())) {
            return false;
        }
        // System.out.println("--- A1");
        if (this.icid != null && !this.icid.matches(cdr.getIcid())) {
            return false;
        }
        // System.out.println("--- A2");
        if (!cdr.hasCalling()) {
            return false;
        }
        // System.out.println("--- A3");
        if (this.callingNetwork != null
                && !this.callingNetwork.matches(cdr.getCalling().getNetwork())) {
            return false;
        }
        // System.out.println("--- A4");
        if (this.callingAccountCode != null
                && !this.callingAccountCode.matches(cdr.getCalling()
                        .getAccountCode())) {
            return false;
        }
        // System.out.println("--- A5");
        //// TODO: refactor the rule
        if (this.callingNumber != null
                && !this.callingNumber.matches(cdr
                        .getCalling().getEffectiveNumber())) {
            return false;
        }
        // System.out.println("--- A6");
        if (this.callingIdentityNumber != null
                && !this.callingIdentityNumber.matches(cdr.getCalling().getEffectiveIdentityNumber())) {
            return false;
        }
        // System.out.println("--- A7");
        if (this.callingPresentation != null
                && !this.callingPresentation.matches(cdr.getCalling().getPresentation().toString())) {
            return false;
        }
        // System.out.println("--- A8");
        if (this.callingName != null
                && !this.callingName.matches(cdr.getCalling().getName())) {
            return false;
        }
        // System.out.println("--- A");

        if (!cdr.hasCalled()) {
            return false;
        }
        if (this.calledNetwork != null
                && !this.calledNetwork.matches(cdr.getCalled().getNetwork())) {
            return false;
        }
        // System.out.println("--- B1");
        if (this.calledAccountCode != null
                && !this.calledAccountCode.matches(cdr.getCalled()
                        .getAccountCode())) {
            return false;
        }
        // System.out.println("--- B2");
        if (this.calledNumber != null
                && !this.calledNumber.matches(cdr.getCalled()
                        .getEffectiveNumber())) {
            return false;
        }
        // System.out.println("--- B3");
        if (this.calledName != null
                && !this.calledName.matches(cdr.getCalled().getName())) {
            return false;
        }
        // System.out.println("--- B4");
        if (this.callingCarrierCode != null
                && !this.callingCarrierCode.matches(cdr.getCalling().getCarrierCode())) {
            return false;
        }
        // System.out.println("--- B5");
        if (this.calledCarrierCode != null
                && !this.calledCarrierCode.matches(cdr.getCalled().getCarrierCode())) {
            return false;
        }
        // System.out.println("--- B6");
        if (this.endCause != null
                && !this.endCause.matches(cdr.getEndCause())) {
            return false;
        }
        // System.out.println("--- B7");
        if (this.billableDuration != null
                && !this.billableDuration.matches(cdr.getBillableDuration())) {
            return false;
        }
        // System.out.println("--- END");

        return true;
    }

    public void appendTo(StringBuffer buffer) {
        String sep = "\n";
        buffer.append("cdr {\n");

        append("complete", this.complete, buffer).append(sep);
        append("icid", this.icid, buffer).append(sep);
        append("end_cause", this.endCause, buffer).append(sep);
        append("billable_duration", this.billableDuration, buffer).append(sep);

        buffer.append("calling {\n");
        append("    carrier_code", this.callingCarrierCode, buffer).append(sep);
        append("    account_code", this.callingAccountCode, buffer).append(sep);
        append("    name", this.callingName, buffer).append(sep);
        append("    network", this.callingNetwork, buffer).append(sep);
        append("    effective_number", this.callingNumber, buffer).append(sep);
        append("    effective_identity_number", this.callingIdentityNumber, buffer).append(sep);
        append("    presentation", this.callingPresentation, buffer).append(sep);
        buffer.append("}\n");

        buffer.append("called {\n");
        append("    carrier_code", this.calledCarrierCode, buffer).append(sep);
        append("    account_code", this.calledAccountCode, buffer).append(sep);
        if (this.calledName != null) {
            append("    name", this.calledName, buffer).append(sep);
        }
        append("    network", this.calledNetwork, buffer).append(sep);
        append("    effective_number", this.calledNumber, buffer).append(sep);
        buffer.append("}\n");

        buffer.append("}");
    }

    private StringBuffer append(String name, IArgumentMatcher matcher,
            StringBuffer buffer) {
        buffer.append(name);
        buffer.append(": ");
        matcher.appendTo(buffer);

        return buffer;
    }

    /**
     * 
     */
    private IArgumentMatcher complete;

    private IArgumentMatcher icid;

    private IArgumentMatcher callingCarrierCode;

    private IArgumentMatcher calledCarrierCode;

    private IArgumentMatcher callingNetwork;

    private IArgumentMatcher callingAccountCode;

    private IArgumentMatcher callingNumber;

    private IArgumentMatcher callingIdentityNumber;

    private IArgumentMatcher callingPresentation;

    private IArgumentMatcher callingName;

    private IArgumentMatcher calledNetwork;

    private IArgumentMatcher calledAccountCode;

    private IArgumentMatcher calledNumber;

    private IArgumentMatcher calledName;

    private IArgumentMatcher endCause;

    private IArgumentMatcher billableDuration;
}
