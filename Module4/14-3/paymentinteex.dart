import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentEx extends StatefulWidget
{
  const PaymentEx({super.key});

  @override
  State<PaymentEx> createState() => _PaymentExState();
}

class _PaymentExState extends State<PaymentEx>
{
  late Razorpay _razorpay;

  void initState() {
    // TODO: implement initState
    // super.initState();

    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }
  
  @override
  Widget build(BuildContext context)
  {
    return Scaffold
      (
      appBar: AppBar(title: Text("Payment"),),
      body: Center( 
        child: ElevatedButton(onPressed: () 
        {
          opencheckout();
        }, child: Text("Pay Now")),
      ),
      );
  }

  _handlePaymentSuccess(PaymentSuccessResponse response) {
    print("Payment Success: ${response.paymentId}");

  }

  _handlePaymentError(PaymentFailureResponse response) {
    print("Payment Error: ${response.code} - ${response.message}");
  }

  _handleExternalWallet(ExternalWalletResponse response) {
    print("External Wallet: ${response.walletName}");
  }

  void opencheckout()
  {
    var options =
    {
      'key': 'rzp_test_Rr3rxC3krXVmE2',
      'amount': 10000,
      // amount in the smallest currency unit (e.g., cents for USD)
      'name': 'Your Company Name',
      'description': 'Product description',
      'prefill': {'contact': '1234567890', 'email': 'test@example.com'},
      'external': {
        'wallets': ['paytm']
      }
    };
    try
    {
      _razorpay.open(options);
    }
    catch(e)
    {
      debugPrint('Error: ${e.toString()}');
    }

  }
}
