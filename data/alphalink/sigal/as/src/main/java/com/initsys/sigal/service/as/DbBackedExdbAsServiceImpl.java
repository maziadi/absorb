package com.initsys.sigal.service.as;

import java.lang.reflect.InvocationTargetException;
import java.util.List;
import java.util.Map;

import org.apache.commons.beanutils.MethodUtils;
import org.apache.commons.beanutils.PropertyUtils;
import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jms.core.JmsTemplate;

import org.springframework.jdbc.CannotGetJdbcConnectionException;

import com.google.protobuf.Message;
import com.initsys.sigal.protocol.SigalProtocolHelper;
import com.initsys.sigal.protocol.Sigal.ExdbQueryRequest;
import com.initsys.sigal.protocol.Sigal.ExdbQueryResponse;
import com.initsys.sigal.protocol.Sigal.ResponseStatus.ResponseStatusCode;
import com.initsys.sigal.service.as.dao.ExdbDao;
import com.initsys.sigal.service.as.dao.VnodbDao;
import com.initsys.sigal.service.as.registry.CallRegistry;
import com.initsys.sigal.vno.VnoUtils;

public class DbBackedExdbAsServiceImpl extends AbstractSigalAsService {

    private CallRegistry callRegistry;
    private ExdbDao exdbDao;
    private VnodbDao vnodbDao;
    private JmsTemplate jmsTemplate;

    public CallRegistry getCallRegistry() {
        return callRegistry;
    }

    public void setCallRegistry(CallRegistry callRegistry) {
        this.callRegistry = callRegistry;
    }

    public ExdbDao getExdbDao() {
        return exdbDao;
    }

    public void setExdbDao(ExdbDao dao) {
        this.exdbDao = dao;
    }

    public VnodbDao getVnodbDao() {
        return vnodbDao;
    }

    public void setVnodbDao(VnodbDao dao) {
        this.vnodbDao = dao;
    }

    public JmsTemplate getJmsTemplate() {
        return jmsTemplate;
    }

    public void setJmsTemplate(JmsTemplate jmsTemplate) {
        this.jmsTemplate = jmsTemplate;
    }

    @Override
    public Message handleQuery(Message query) {
        ExdbQueryRequest exdbQuery = (ExdbQueryRequest) query;
        ExdbQueryResponse.Builder response = ExdbQueryResponse.newBuilder();

        response.setVersion(1);

        try {
            List<ExdbEntry> list;
            list = getExdbDao().queryByAccountCode(exdbQuery);
            ExdbEntry entry = list.isEmpty() ? null : list.get(0);

            if (entry == null) {
                response.setStatus(SigalProtocolHelper.buildStatus(
                        ResponseStatusCode.NOT_FOUND, null));
            } else {
              String vnoName = VnoUtils.getVnoName(entry.getCarrierCode());
              VnodbEntry vnoEntry = getVnodbDao().queryDbByRef(vnoName);

              if (vnoEntry == null) {
                response.setStatus(SigalProtocolHelper.buildStatus(
                        ResponseStatusCode.NOT_FOUND, null));
              } else {
                addCallCounters(response, entry);
                response.setMaxVnoCalls(vnoEntry.getMaxCalls());
                response.setStatus(SigalProtocolHelper.buildStatus(
                      ResponseStatusCode.OK, null));
                copyEntryToResponse(response, entry);
              }
            }
            sleep(18000);
            return response.build();
        } catch (IllegalAccessException e) {
            throw new RuntimeException(
                    "An unexpected error occured while querying EXDB", e);
        } catch (InvocationTargetException e) {
            // TODO: better exception handling
            throw new RuntimeException(
                    "An unexpected error occured while querying EXDB", e);
        } catch (NoSuchMethodException e) {
            // TODO: better exception handling
            throw new RuntimeException(
                    "An unexpected error occured while querying EXDB", e);
        } catch (final CannotGetJdbcConnectionException e) {
            response.setStatus(SigalProtocolHelper.buildStatus(
                  ResponseStatusCode.ERROR, "DB Connection failure"));
            return response.build();
        }
    }

    private void addCallCounters(final ExdbQueryResponse.Builder response,
            final ExdbEntry entry) {
        response.setCallCount(getCallRegistry().getCountByAccount(
                entry.getAccountCode()));
        response.setVnoCallCount(getCallRegistry().getCountByVno(
                VnoUtils.getVnoName(entry.getCarrierCode())));
        response.setInboundCallCount(getCallRegistry()
                .getInboundCountByAccount(entry.getAccountCode()));
        response.setOutboundCallCount(getCallRegistry()
                .getOutboundCountByAccount(entry.getAccountCode()));
    }

    @SuppressWarnings("unchecked")
    private void copyEntryToResponse(ExdbQueryResponse.Builder response,
            ExdbEntry entry) throws IllegalAccessException,
            InvocationTargetException, NoSuchMethodException {
        Map<String, Object> descs = (Map<String, Object>) PropertyUtils
                .describe(entry);
        for (Map.Entry<String, Object> propEntry : descs.entrySet()) {
            if ("class".equals(propEntry.getKey())
                    || propEntry.getValue() == null) {
                continue;
            }

            MethodUtils.invokeMethod(response, "set"
                    + StringUtils.capitalize(propEntry.getKey()), propEntry
                    .getValue());
        }
    }
}