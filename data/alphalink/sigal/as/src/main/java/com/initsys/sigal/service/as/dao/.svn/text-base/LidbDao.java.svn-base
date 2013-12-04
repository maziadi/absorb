package com.initsys.sigal.service.as.dao;

import java.util.List;

import com.initsys.sigal.protocol.Sigal.LidbQueryRequest;
import com.initsys.sigal.protocol.Sigal.LidbUpdateRequest;
import com.initsys.sigal.service.as.LidbEntry;

public interface LidbDao {

    public abstract int updateRecord(LidbUpdateRequest request);

    public abstract List<LidbEntry> queryDbByAccountCode(
            LidbQueryRequest lidbQuery);

    public abstract List<LidbEntry> queryDbByNumber(LidbQueryRequest lidbQuery);

}