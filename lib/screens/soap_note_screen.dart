import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/soap_note.dart';
import '../models/conversation.dart';
import '../providers/conversation_provider.dart';
import '../services/database_helper.dart';

class SoapNoteScreen extends StatefulWidget {
  final Conversation conversation;
  final SoapNote? existingSoapNote;

  const SoapNoteScreen({
    super.key,
    required this.conversation,
    this.existingSoapNote,
  });

  @override
  State<SoapNoteScreen> createState() => _SoapNoteScreenState();
}

class _SoapNoteScreenState extends State<SoapNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _chiefComplaintController = TextEditingController();
  final _subjectiveController = TextEditingController();
  final _objectiveController = TextEditingController();
  final _assessmentController = TextEditingController();
  final _planController = TextEditingController();
  final _vitalSignsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _medicalHistoryController = TextEditingController();

  bool _isLoading = false;
  bool _isFinalized = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.existingSoapNote != null) {
      final soap = widget.existingSoapNote!;
      _chiefComplaintController.text = soap.chiefComplaint;
      _subjectiveController.text = soap.subjective;
      _objectiveController.text = soap.objective;
      _assessmentController.text = soap.assessment;
      _planController.text = soap.plan;
      _vitalSignsController.text = soap.vitalSigns ?? '';
      _allergiesController.text = soap.allergies ?? '';
      _medicationsController.text = soap.medications ?? '';
      _medicalHistoryController.text = soap.medicalHistory ?? '';
      _isFinalized = soap.isFinalized;
    } else {
      final suggestedSoap = SoapNote.fromConversation(
        widget.conversation,
        widget.conversation.doctorName,
      );
      _subjectiveController.text = suggestedSoap.subjective;
    }
  }

  @override
  void dispose() {
    _chiefComplaintController.dispose();
    _subjectiveController.dispose();
    _objectiveController.dispose();
    _assessmentController.dispose();
    _planController.dispose();
    _vitalSignsController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _medicalHistoryController.dispose();
    super.dispose();
  }

  Future<void> _saveSoapNote({bool finalize = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final soapNote = SoapNote(
        id: widget.existingSoapNote?.id,
        conversationId: widget.conversation.id!,
        patientId: widget.conversation.patientName,
        chiefComplaint: _chiefComplaintController.text,
        subjective: _subjectiveController.text,
        objective: _objectiveController.text,
        assessment: _assessmentController.text,
        plan: _planController.text,
        vitalSigns: _vitalSignsController.text.isEmpty ? null : _vitalSignsController.text,
        allergies: _allergiesController.text.isEmpty ? null : _allergiesController.text,
        medications: _medicationsController.text.isEmpty ? null : _medicationsController.text,
        medicalHistory: _medicalHistoryController.text.isEmpty ? null : _medicalHistoryController.text,
        createdAt: widget.existingSoapNote?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.conversation.doctorName,
        isFinalized: finalize || _isFinalized,
      );

      if (widget.existingSoapNote != null) {
        await DatabaseHelper.instance.updateSoapNote(soapNote);
      } else {
        await DatabaseHelper.instance.insertSoapNote(soapNote);
      }

      if (mounted) {
        setState(() {
          _isFinalized = finalize || _isFinalized;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(finalize ? 'SOAP note finalized successfully' : 'SOAP note saved as draft'),
            backgroundColor: finalize ? Colors.green : Colors.blue,
          ),
        );

        if (finalize) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving SOAP note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingSoapNote != null ? 'Edit SOAP Note' : 'Create SOAP Note'),
        actions: [
          if (!_isFinalized) ...[
            TextButton(
              onPressed: _isLoading ? null : () => _saveSoapNote(finalize: false),
              child: const Text('Save Draft'),
            ),
            TextButton(
              onPressed: _isLoading ? null : () => _saveSoapNote(finalize: true),
              child: const Text('Finalize'),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isFinalized)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          border: Border.all(color: Colors.green),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'This SOAP note has been finalized and cannot be edited.',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (_isFinalized) const SizedBox(height: 16),
                    
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Patient Information',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text('Patient: ${widget.conversation.patientName}'),
                            Text('Doctor: ${widget.conversation.doctorName}'),
                            Text('Date: ${widget.conversation.startTime.toString().split(' ')[0]}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildSectionCard(
                      'Chief Complaint',
                      _chiefComplaintController,
                      'Primary reason for the patient\'s visit',
                      maxLines: 2,
                    ),

                    _buildSectionCard(
                      'Subjective',
                      _subjectiveController,
                      'Patient\'s description of symptoms, medical history, and concerns',
                      maxLines: 4,
                    ),

                    _buildSectionCard(
                      'Objective',
                      _objectiveController,
                      'Observable findings, physical exam results, vital signs',
                      maxLines: 4,
                    ),

                    _buildSectionCard(
                      'Assessment',
                      _assessmentController,
                      'Medical diagnosis or clinical impression',
                      maxLines: 3,
                    ),

                    _buildSectionCard(
                      'Plan',
                      _planController,
                      'Treatment plan, medications, follow-up instructions',
                      maxLines: 4,
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Additional Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),

                    _buildOptionalField('Vital Signs', _vitalSignsController),
                    _buildOptionalField('Allergies', _allergiesController),
                    _buildOptionalField('Current Medications', _medicationsController),
                    _buildOptionalField('Medical History', _medicalHistoryController),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard(String title, TextEditingController controller, String hint, {int maxLines = 3}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                border: const OutlineInputBorder(),
              ),
              maxLines: maxLines,
              enabled: !_isFinalized,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'This field is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionalField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        maxLines: 2,
        enabled: !_isFinalized,
      ),
    );
  }
}