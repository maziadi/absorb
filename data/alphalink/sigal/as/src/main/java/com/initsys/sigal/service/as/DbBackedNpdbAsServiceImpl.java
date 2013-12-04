package com.initsys.sigal.service.as;

import java.util.List;

import com.google.protobuf.Message;
import com.initsys.sigal.protocol.SigalProtocolHelper;
import com.initsys.sigal.protocol.Sigal.NpdbQueryRequest;
import com.initsys.sigal.protocol.Sigal.NpdbQueryResponse;
import com.initsys.sigal.protocol.Sigal.ResponseStatus.ResponseStatusCode;
import com.initsys.sigal.service.as.dao.NpdbDao;

public class DbBackedNpdbAsServiceImpl extends AbstractSigalAsService {

    private NpdbDao dao;

    public NpdbDao getDao() {
        return dao;
    }

    public void setDao(NpdbDao dao) {
        this.dao = dao;
    }

    @Override
    public Message handleQuery(Message query) {
        NpdbQueryRequest request = (NpdbQueryRequest) query;
        NpdbQueryResponse.Builder response = NpdbQueryResponse.newBuilder();

        response.setVersion(1);
        response.setNumber(request.getNumber());
        List<NpdbEntry> list = getDao().query(request);
        NpdbEntry entry = list.isEmpty() ? null : list.get(0);
        if (entry == null) {
            response.setStatus(SigalProtocolHelper.buildStatus(
                    ResponseStatusCode.NOT_FOUND, null));
        } else {
            if (entry.getPrefix() == null) {
                response.setStatus(SigalProtocolHelper.buildStatus(
                        ResponseStatusCode.NOT_FOUND, null));
            } else {
                response.setPrefix(entry.getPrefix());
                response.setStatus(SigalProtocolHelper.buildStatus(
                        ResponseStatusCode.OK, null));
            }
        }

        sleep(15000);
        return response.build();
    }
}
