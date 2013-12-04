package com.initsys.sigal.service.as.dao;

import java.util.List;

import com.initsys.sigal.protocol.Sigal.MlidbQueryRequest;
import com.initsys.sigal.protocol.Sigal.MlidbUpdateRequest;
import com.initsys.sigal.service.as.MlidbEntry;

public interface MlidbDao {

    public abstract int updateDatabase(MlidbUpdateRequest request);

    public abstract List<MlidbEntry> queryDbByMsisdn(MlidbQueryRequest mlidbQuery);

}
