%define valid_req_str "HTTP/1.1 200 OK"
%strlen valid_req_len valid_req_str

%define connection_str "Connection: "
%strlen connection_len connection_str

%define content_type_str "Content-Type: "
%strlen content_type_len content_type_str

%define content_length_str "Content-Length: "
%strlen content_length_len content_length_str

%define newline_str `\r\n`
%strlen newline_len newline_str

%define not_found_str `HTTP/1.1 404 Not Found\r\n\r\n`
%strlen not_found_len not_found_str
