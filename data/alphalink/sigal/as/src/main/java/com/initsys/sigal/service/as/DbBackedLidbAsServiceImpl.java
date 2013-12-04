package com.initsys.sigal.service.as;

import java.lang.reflect.InvocationTargetException;
import java.util.List;
import java.util.Map;

import org.apache.commons.beanutils.MethodUtils;
import org.apache.commons.beanutils.PropertyUtils;
import org.apache.commons.lang.StringUtils;

import org.springframework.jdbc.CannotGetJdbcConnectionException;

import com.google.protobuf.Message;
import com.initsys.sigal.protocol.SigalProtocolHelper;
import com.initsys.sigal.protocol.Sigal.LidbQueryRequest;
import com.initsys.sigal.protocol.Sigal.LidbQueryResponse;
import com.initsys.sigal.protocol.Sigal.ResponseStatus.ResponseStatusCode;
import com.initsys.sigal.service.as.dao.LidbDao;
import com.initsys.sigal.service.as.dao.VnodbDao;
import com.initsys.sigal.service.as.registry.CallRegistry;
import com.initsys.sigal.vno.VnoUtils;

public class DbBackedLidbAsServiceImpl extends AbstractSigalAsService {

    private LidbDao lidbDao;
    private VnodbDao vnodbDao;
    private CallRegistry callRegistry;

    public LidbDao getLidbDao() {
        return lidbDao;
    }

    public void setLidbDao(LidbDao dao) {
        this.lidbDao = dao;
    }

    public VnodbDao getVnodbDao() {
        return vnodbDao;
    }

    public void setVnodbDao(VnodbDao dao) {
        this.vnodbDao = dao;
    }

    @SuppressWarnings("unchecked")
    private void copyEntryToResponse(LidbQueryResponse.Builder response,
            LidbEntry entry) throws IllegalAccessException,
            InvocationTargetException, NoSuchMethodException {
        final Map<String, Object> descs = PropertyUtils.describe(entry);
        for (final Map.Entry<String, Object> propEntry : descs.entrySet()) {
            if ("class".equals(propEntry.getKey())
                    || propEntry.getValue() == null) {
                continue;
            }

            MethodUtils.invokeMethod(response, "set"
                    + StringUtils.capitalize(propEntry.getKey()), propEntry
                    .getValue());
        }
    }

    public CallRegistry getCallRegistry() {
        return callRegistry;
    }

    @Override
    public Message handleQuery(Message query) {
        final LidbQueryRequest lidbQuery = (LidbQueryRequest) query;
        final LidbQueryResponse.Builder response = LidbQueryResponse
                .newBuilder();

        response.setVersion(1);

        try {
            final List<LidbEntry> list = lidbQuery.hasNumber() ? getLidbDao()
                    .queryDbByNumber(lidbQuery) : getLidbDao()
                    .queryDbByAccountCode(lidbQuery);
            final LidbEntry entry = list.isEmpty() ? null : list.get(0);

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
                response.setMaxVnoCalls(vnoEntry.getMaxCalls());
                addCallCounters(response, entry);
                response.setStatus(SigalProtocolHelper.buildStatus(
                      ResponseStatusCode.OK, null));
                copyEntryToResponse(response, entry);
              }
            }
            sleep(30000);
            return response.build();
        } catch (final IllegalAccessException e) {
            throw new RuntimeException(
                    "An unexpected error occured while querying LIDB", e);
        } catch (final InvocationTargetException e) {
            // TODO: better exception handling
            throw new RuntimeException(
                    "An unexpected error occured while querying LIDB", e);
        } catch (final NoSuchMethodException e) {
            // TODO: better exception handling
            throw new RuntimeException(
                    "An unexpected error occured while querying LIDB", e);
        } catch (final CannotGetJdbcConnectionException e) {
            response.setStatus(SigalProtocolHelper.buildStatus(
                  ResponseStatusCode.ERROR, "DB Connection failure"));
            return response.build();
        }
    }

    private void addCallCounters(final LidbQueryResponse.Builder response,
            final LidbEntry entry) {
        response.setVnoCallCount(getCallRegistry().getCountByVno(
                VnoUtils.getVnoName(entry.getCarrierCode())));

        response.setInboundCallCount(getCallRegistry()
                .getInboundCountByAccount(entry.getAccountCode()));
        response.setOutboundCallCount(getCallRegistry()
                .getOutboundCountByAccount(entry.getAccountCode()));
        response.setCallCount(getCallRegistry().getCountByAccount(
                entry.getAccountCode()));
    }

    public void setCallRegistry(CallRegistry callRegistry) {
        this.callRegistry = callRegistry;
    }
}
