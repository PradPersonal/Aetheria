function handler(event) {
    var request = event.request;
    var headers = request.headers;

    // Add security headers
    headers['x-content-type-options'] = { value: 'nosniff' };
    headers['x-frame-options'] = { value: 'DENY' };
    headers['x-xss-protection'] = { value: '1; mode=block' };
    headers['strict-transport-security'] = { 
        value: 'max-age=31536000; includeSubDomains' 
    };
    headers['referrer-policy'] = { 
        value: 'strict-origin-when-cross-origin' 
    };

    // Add cache headers for static assets
    var uri = request.uri;
    if (uri.match(/\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$/)) {
        headers['cache-control'] = { 
            value: 'public, max-age=31536000, immutable' 
        };
    }

    return request;
}