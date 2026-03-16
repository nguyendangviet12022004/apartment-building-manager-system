package com.viet.backend.config;

import org.springframework.context.annotation.Configuration;

@Configuration
public class VNPayConfig {

    public static final String TMN_CODE    = "6F2H9SYK";
    public static final String HASH_SECRET = "JWKE67XFTHZ9P7O995X00T0FT6Q079X2";
    public static final String PAY_URL     = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html";
    public static final String RETURN_URL = "myapp://vnpay-return";
    public static final String VERSION     = "2.1.0";
    public static final String COMMAND     = "pay";
    public static final String CURR_CODE   = "VND";
    public static final String LOCALE      = "vn";
    public static final String ORDER_TYPE  = "other";
    public static final String TIMEZONE    = "Asia/Ho_Chi_Minh";

}