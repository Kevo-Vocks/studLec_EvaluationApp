import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evaluation_app/model/user_model.dart';
import 'package:flutter/material.dart';

class ExamCardPDF {
  static Future<void> generate({
    required UserModel user,
    required String department,
    required String program,
    required List<QueryDocumentSnapshot> units,
    required BuildContext context,
  }) async {
    try {
      if (units.isEmpty) {
        throw Exception('No units provided for PDF');
      }

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Exam Card', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Student Information', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Name: ${user.firstname}'),
              pw.Text('Registration Number: ${user.regno}'),
              pw.Text('Department: ${department.isEmpty ? "Unknown" : department}'),
              pw.Text('Program: ${program.isEmpty ? "Unknown" : program}'),
              pw.Text(user.year),
              pw.Text(user.semester),
              pw.SizedBox(height: 20),
              pw.Text('Registered Units', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Unit Code', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Unit Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...units.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(data['unitCode']?.toString() ?? 'Unknown'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(data['unitName']?.toString() ?? 'Unknown'),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ],
          ),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating exam card: $e')),
      );
      rethrow;
    }
  }
}