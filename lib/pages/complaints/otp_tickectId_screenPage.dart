import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class OtpTickectidScreenpage extends StatelessWidget {
  final String ticketId;
  final String? otp;
  const OtpTickectidScreenpage({
    super.key,
    required this.ticketId,
     this.otp,
  });

  @override
  Widget build(BuildContext context) {
    void copyToClipboard(BuildContext context, String text) {
      Clipboard.setData(ClipboardData(text: text));

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket ID copied to clipboard!'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
             
              Container(
                width: 80.0,
                height: 80.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDFCF5), 
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: const Color(0xFF1CB17F), 
                    size: 50.0,
                  ),
                ),
              ),
              const SizedBox(height: 30.0),

              // "Ticket Created!" Title
              Text(
                'Ticket Created!',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10.0),

              // Subtitle description
              Text(
              ' Please save this Ticket ID and OTP. You will need to provide them to the technician for verification during the service visit',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 30.0),

              // The Ticket ID container
              InkWell(
                onTap: () => copyToClipboard(context, ticketId),
                child: SizedBox(
                  width: 500,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 25.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(
                        color: const Color(0xFFD1D5DB),
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Column(
                      children: [
                        // "YOUR TICKET ID" text
                        Text(
                          'YOUR TICKET ID',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF94A3B8), // Gray-blue label
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10.0),
//============================== Ticket ID and Copy Icon=========================
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ticketId,
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Icon(
                              Icons.copy_rounded,
                              color: const Color(0xFF94A3B8),
                              size: 24.0,
                            ),
                          ],
                        ),
                        SizedBox(height: 15,),
                        //Generate Otp
                        Text(
                          'OTP Number',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF94A3B8), // Gray-blue label
                            letterSpacing: 1.2,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                            otp!,
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Icon(
                              Icons.copy_rounded,
                              color: const Color(0xFF94A3B8),
                              size: 24.0,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30.0),

              // "Done" Button
              SizedBox(
                width: 500,
                child: ElevatedButton(
                  onPressed: () {
                      context.push('/Dashboard');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 253, 135, 25), 
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20.0,
                    ), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
