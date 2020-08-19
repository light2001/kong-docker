local _M = {}

function _M.serialize(ngx, kong)
    local authenticated_entity
    if ngx.ctx.authenticated_credential ~= nil then
        authenticated_entity = {
            id = ngx.ctx.authenticated_credential.id,
            consumer_id = ngx.ctx.authenticated_credential.consumer_id
        }
    end

    local request_uri = ngx.var.request_uri or ""
    local tcp_body_log_ctx = kong.ctx.tcp_body_log or {}

    return {
        request = {
            uri = request_uri,
            url = ngx.var.scheme .. "://" .. ngx.var.host .. ":" .. ngx.var.server_port .. request_uri,
            querystring = ngx.req.get_uri_args(), -- parameters, as a table
            method = ngx.req.get_method(), -- http method
            headers = ngx.req.get_headers(),
            size = ngx.var.request_length,
            body = tcp_body_log_ctx.request_body
        },
        response = {
            status = ngx.status,
            headers = ngx.resp.get_headers(),
            size = ngx.var.bytes_sent,
            body = tcp_body_log_ctx.response_body
        },
        latencies = {
            kong = (ngx.ctx.KONG_ACCESS_TIME or 0) +
                    (ngx.ctx.KONG_RECEIVE_TIME or 0),
            proxy = ngx.ctx.KONG_WAITING_TIME or -1,
            request = ngx.var.request_time * 1000
        },
        tries = (ngx.ctx.balancer_data or {}).tries,
        authenticated_entity = authenticated_entity,
        upstream_uri = ngx.var.upstream_uri,
        client_ip = ngx.var.remote_addr,
        started_at = ngx.req.start_time() * 1000
    }
end

return _M 