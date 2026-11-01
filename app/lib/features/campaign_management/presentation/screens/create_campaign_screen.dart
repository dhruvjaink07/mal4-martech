import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/colors.dart';
import '../../../../core/design_system/spacing.dart';
import '../../../../core/design_system/widgets/app_button.dart';
import '../../../../core/design_system/widgets/app_card.dart';
import '../../../../core/design_system/widgets/app_text_field.dart';
import '../../../../core/providers/persona_provider.dart';
import '../../domain/campaign_repository.dart';
import '../../domain/value_objects.dart';
import '../providers/campaign_providers.dart';

class CreateCampaignScreen extends ConsumerStatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  ConsumerState<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends ConsumerState<CreateCampaignScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _objectiveController;
  late final TextEditingController _budgetController;
  late final TextEditingController _segmentController;
  late final TextEditingController _reachController;
  late final TextEditingController _assetLinkController;

  String _costCenter = 'CC-MKTG-GLOBAL';
  final List<String> _costCenters = [
    'CC-MKTG-GLOBAL',
    'CC-RETENTION',
    'CC-FINTECH-ACQ',
    'CC-CORP-BRAND',
    'CC-PRODUCT-LAUNCH',
  ];

  final List<String> _availableChannels = [
    'Meta',
    'Google Ads',
    'TikTok',
    'LinkedIn',
    'Email',
    'Push Notifications',
    'SMS',
    'Display',
    'Direct Mail',
  ];
  final Set<String> _selectedChannels = {'Meta', 'Google Ads'};

  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 37));

  int _doaTier = 1;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Spring Omni-Channel Brand Accelerator');
    _objectiveController = TextEditingController(
      text: 'Accelerate mid-funnel conversion across core demographic cohorts through tailored visual creatives.',
    );
    _budgetController = TextEditingController(text: '35000');
    _segmentController = TextEditingController(text: 'High-LTV Online Shoppers (25-45)');
    _reachController = TextEditingController(text: '650000');
    _assetLinkController = TextEditingController(text: 'https://assets.enterprise.cdn/creatives/spring_2027_deck.pdf');

    _updateDoaTier();
    _budgetController.addListener(_updateDoaTier);
  }

  void _updateDoaTier() {
    final amount = double.tryParse(_budgetController.text) ?? 0.0;
    setState(() {
      _doaTier = BudgetAllocation.calculateDoaTier(amount);
    });
  }

  @override
  void dispose() {
    _budgetController.removeListener(_updateDoaTier);
    _nameController.dispose();
    _objectiveController.dispose();
    _budgetController.dispose();
    _segmentController.dispose();
    _reachController.dispose();
    _assetLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.defenseGreen,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _handleSave({required bool submitImmediately}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedChannels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one distribution channel.'),
          backgroundColor: AppColors.defenseRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final activePersona = ref.read(currentPersonaProvider);
      final amount = double.parse(_budgetController.text);
      final reach = int.tryParse(_reachController.text) ?? 100000;

      final input = CampaignDraftInput(
        name: _nameController.text.trim(),
        objective: _objectiveController.text.trim(),
        amount: amount,
        currency: 'USD',
        costCenter: _costCenter,
        segmentName: _segmentController.text.trim(),
        targetRegions: const ['North America', 'Europe'],
        channels: _selectedChannels.toList(),
        estimatedReach: reach,
        startDate: _startDate,
        endDate: _endDate,
        assetLinks: [_assetLinkController.text.trim()],
      );

      final notifier = ref.read(campaignListProvider.notifier);
      final campaign = await notifier.createDraft(input, activePersona.id, activePersona.name);

      if (submitImmediately) {
        await notifier.submitForReview(campaign.id, campaign.version, activePersona.id, activePersona.name);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              submitImmediately
                  ? 'Campaign created and submitted to Stage 1 (Creative & Brand)!'
                  : 'Campaign draft saved successfully.',
            ),
            backgroundColor: AppColors.defenseGreen,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save campaign: $e'),
            backgroundColor: AppColors.defenseRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activePersona = ref.watch(currentPersonaProvider);
    final dateFmt = DateFormat('MMM dd, yyyy');
    final durationDays = _endDate.difference(_startDate).inDays;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'New Campaign Proposal',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Submitter attribution banner
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                backgroundColor: isDark ? AppColors.darkElevated : const Color(0xFFF1F5F9),
                child: Row(
                  children: [
                    const Icon(Icons.person_pin_rounded, size: 18, color: AppColors.defenseGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Authoring as: ${activePersona.name} (${activePersona.role})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Section 1: Overview
              _buildSectionHeader('1. CAMPAIGN METADATA', isDark),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Campaign Name',
                hint: 'e.g. Q4 Global Holiday Omni-Channel Surge',
                controller: _nameController,
                validator: (val) {
                  if (val == null || val.trim().length < 5) {
                    return 'Please enter at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Campaign Objective',
                hint: 'Describe target outcomes, KPIs, and strategy',
                controller: _objectiveController,
                maxLines: 3,
                validator: (val) {
                  if (val == null || val.trim().length < 10) {
                    return 'Objective must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Section 2: Budget & DOA
              _buildSectionHeader('2. BUDGET & DOA GOVERNANCE', isDark),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: AppTextField(
                      label: 'Budget Amount (USD)',
                      hint: '45000',
                      controller: _budgetController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefix: const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.attach_money_rounded, size: 18),
                      ),
                      validator: (val) {
                        final parsed = double.tryParse(val ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Enter valid amount';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DOA THRESHOLD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: AppColors.defenseGreen.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_outlined, size: 16, color: AppColors.defenseGreen),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Tier $_doaTier\n${_doaTier == 1 ? "Lead" : _doaTier == 2 ? "Director" : "Executive"}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.defenseGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Cost Center Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COST CENTER ALLOCATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _costCenter,
                        isExpanded: true,
                        dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        items: _costCenters.map((cc) {
                          return DropdownMenuItem<String>(
                            value: cc,
                            child: Text(
                              cc,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _costCenter = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Section 3: Audience & Schedule
              _buildSectionHeader('3. AUDIENCE & FLIGHT SCHEDULE', isDark),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Audience Segment',
                hint: 'e.g. High-LTV Online Shoppers (25-45)',
                controller: _segmentController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Audience segment required';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Estimated Audience Reach',
                hint: '650000',
                controller: _reachController,
                keyboardType: TextInputType.number,
                prefix: const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.people_outline_rounded, size: 18),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Channels Chips
              Text(
                'DISTRIBUTION CHANNELS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _availableChannels.map((ch) {
                  final isSelected = _selectedChannels.contains(ch);
                  return FilterChip(
                    label: Text(ch),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedChannels.add(ch);
                        } else {
                          _selectedChannels.remove(ch);
                        }
                      });
                    },
                    backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    selectedColor: AppColors.defenseGreen.withValues(alpha: 0.2),
                    side: BorderSide(
                      color: isSelected ? AppColors.defenseGreen : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppColors.defenseGreen : (isDark ? AppColors.darkForeground : AppColors.lightForeground),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Date Range Picker Box
              InkWell(
                onTap: _pickDateRange,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range_rounded, color: AppColors.defenseGreen, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FLIGHT WINDOW ($durationDays DAYS)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${dateFmt.format(_startDate)} – ${dateFmt.format(_endDate)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkForeground : AppColors.lightForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppColors.defenseGreen),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Section 4: Creative & Compliance Assets
              _buildSectionHeader('4. ASSET BUNDLE & CREATIVE ASSETS', isDark),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: 'Asset URL / Creative Bundle Link',
                hint: 'https://assets.enterprise.cdn/creatives/...',
                controller: _assetLinkController,
                prefix: const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.link_rounded, size: 18),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Save Draft',
                      variant: AppButtonVariant.secondary,
                      isLoading: _isSubmitting,
                      onPressed: () => _handleSave(submitImmediately: false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      label: 'Submit (Stage 1)',
                      variant: AppButtonVariant.primary,
                      isLoading: _isSubmitting,
                      onPressed: () => _handleSave(submitImmediately: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: isDark ? AppColors.darkMutedText : AppColors.lightMutedText,
      ),
    );
  }
}
