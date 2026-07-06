import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../services/database_service.dart';
import '../../../services/ai_matching_service.dart';
import '../../../models/opportunity_model.dart';
import '../../../models/student_profile_model.dart';
import '../../../core/ui_helper.dart';
import '../../../core/theme.dart';
import 'student_profile_view_screen.dart';

class BrowseOpportunitiesView extends StatefulWidget {
  const BrowseOpportunitiesView({super.key});

  @override
  State<BrowseOpportunitiesView> createState() => _BrowseOpportunitiesViewState();
}

class _BrowseOpportunitiesViewState extends State<BrowseOpportunitiesView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedWorkType;
  final List<String> _workTypes = ['Remote', 'In-Person', 'Hybrid'];
  
  Stream<StudentProfileModel?>? _profileStream;
  Stream<List<OpportunityModel>>? _opportunitiesStream;
  String? _lastUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<User?>(context);
    if (user != null && user.uid != _lastUserId) {
      final dbService = DatabaseService();
      _profileStream = dbService.getStudentProfileStream(user.uid);
      _opportunitiesStream = dbService.getOpportunities();
      _lastUserId = user.uid;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();

    if (user == null || _profileStream == null || _opportunitiesStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<StudentProfileModel?>(
      stream: _profileStream,
      builder: (context, profileSnapshot) {
        final studentProfile = profileSnapshot.data;

        return StreamBuilder<List<OpportunityModel>>(
          stream: _opportunitiesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            var opportunities = snapshot.data ?? [];

            // Apply Search Filtering
            if (_searchQuery.isNotEmpty) {
              opportunities = opportunities.where((opp) {
                final searchLower = _searchQuery.toLowerCase();
                return opp.title.toLowerCase().contains(searchLower) ||
                    opp.description.toLowerCase().contains(searchLower);
              }).toList();
            }

            // Apply Work Type Filtering
            if (_selectedWorkType != null) {
              opportunities = opportunities.where((opp) => opp.workType == _selectedWorkType).toList();
            }

            return Column(
              children: [
                _buildSearchAndFilters(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          _opportunitiesStream = DatabaseService().getOpportunities();
                          _profileStream = DatabaseService().getStudentProfileStream(user.uid);
                        }
                      });
                    },
                    child: opportunities.isEmpty 
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              _buildProfileHeader(context, user, studentProfile),
                              UIHelper.buildEmptyState(
                                context: context,
                                icon: Icons.search_off_rounded,
                                title: 'No match found',
                                message: 'We couldn\'t find any tasks matching your criteria. Try adjusting your search or filters.',
                                actionLabel: 'Clear All Filters',
                                onAction: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _selectedWorkType = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: opportunities.length + 1,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 10, bottom: 10),
                                child: _buildProfileHeader(context, user, studentProfile),
                              );
                            }
                            final opp = opportunities[index - 1];
                            return _buildOpportunityCard(context, opp, studentProfile);
                          },
                        ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore Opportunities',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search tasks or companies...',
              prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.primary),
              suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 24), // Increased icon size for better target
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48), // Ensure touch target
                  )
                : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface, // Better contrast against container
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            style: GoogleFonts.manrope(fontSize: 14),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                 Container(
                   height: 48, // Enforce min touch target height
                   child: ChoiceChip(
                     label: const Text('All'),
                     selected: _selectedWorkType == null,
                     onSelected: (selected) {
                       if (selected) setState(() => _selectedWorkType = null);
                     },
                     backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                     selectedColor: Theme.of(context).colorScheme.primary,
                     labelStyle: GoogleFonts.manrope(
                       fontSize: 14, 
                       fontWeight: _selectedWorkType == null ? FontWeight.bold : FontWeight.normal,
                       color: _selectedWorkType == null ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
                     ),
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                     shape: const StadiumBorder(),
                     side: BorderSide.none,
                   ),
                 ),
                ..._workTypes.map((type) => Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                   child: Container(
                     height: 48, // Enforce min touch target height
                     child: ChoiceChip(
                       label: Text(type),
                       selected: _selectedWorkType == type,
                       onSelected: (selected) {
                         setState(() => _selectedWorkType = selected ? type : null);
                       },
                       backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                       selectedColor: Theme.of(context).colorScheme.primary,
                       labelStyle: GoogleFonts.manrope(
                         fontSize: 14, 
                         fontWeight: _selectedWorkType == type ? FontWeight.bold : FontWeight.normal,
                         color: _selectedWorkType == type ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
                       ),
                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                       shape: const StadiumBorder(),
                       side: BorderSide.none,
                     ),
                   ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunityCard(BuildContext context, OpportunityModel opp, StudentProfileModel? studentProfile) {
    if (studentProfile == null) {
      return _buildCardShell(context, opp, null, false, null, studentProfile);
    }

    return FutureBuilder<AIMatchResult>(
      future: AIMatchingService().getAIMatch(studentProfile, opp),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCardShell(context, opp, null, false, null, studentProfile, isLoading: true);
        }
        final result = snapshot.data;
        return _buildCardShell(context, opp, result?.score, (result?.score ?? 0) >= 70, result?.explanation, studentProfile);
      },
    );
  }

  Widget _buildCardShell(
    BuildContext context,
    OpportunityModel opp,
    int? score,
    bool isHighMatch,
    String? explanation,
    StudentProfileModel? studentProfile, {
    bool isLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Hero(
        tag: 'opp-${opp.id}',
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: InkWell(
            onTap: () => context.goNamed('studentOpportunityDetails', pathParameters: {'id': opp.id ?? ''}),
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      isLoading ? _buildLoadingBadge() : _buildMatchBadge(score, isHighMatch, explanation),
                      IconButton(
                        icon: Icon(
                          (studentProfile?.bookmarks.contains(opp.id) ?? false)
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: (studentProfile?.bookmarks.contains(opp.id) ?? false)
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[500],
                          size: 24,
                        ),
                        onPressed: () {
                          if (studentProfile != null && opp.id != null) {
                            DatabaseService().toggleBookmark(studentProfile.uid, opp.id!);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    opp.title,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(opp.duration, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const SizedBox(width: 20),
                      Icon(Icons.location_on_outlined, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(opp.workType ?? 'Remote', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User? user, StudentProfileModel? profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (profile != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentProfileViewScreen(profile: profile),
                  ),
                );
              }
            },
            child: CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              child: Text(
                (profile?.name ?? user?.displayName ?? 'S').substring(0, 1).toUpperCase(),
                style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.getAdaptivePrimary(context)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (profile != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentProfileViewScreen(profile: profile),
                    ),
                  );
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.name ?? user?.displayName ?? 'Student',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getAdaptiveTextPrimary(context),
                    ),
                  ),
                  if (profile?.major != null)
                    Text(
                      '${profile!.major} · ${profile.university}',
                      style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.getAdaptiveTextSecondary(context)),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 12, color: AppTheme.secondary),
                      const SizedBox(width: 4),
                      Text(
                        'AI-powered matching active',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: AppTheme.getAdaptivePrimary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => context.goNamed('studentEditProfile'),
            icon: Icon(Icons.edit_outlined, color: AppTheme.getAdaptivePrimary(context), size: 22),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildMatchBadge(int? score, bool isHighMatch, String? explanation) {
    Color bgColor = Theme.of(context).brightness == Brightness.dark ? Colors.grey[850]! : Colors.grey[100]!;
    Color textColor = Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[700]!;
    if (score != null) {
      if (score >= 70) {
        bgColor = Theme.of(context).brightness == Brightness.dark ? Colors.green.withOpacity(0.2) : Colors.green[50]!;
        textColor = Theme.of(context).brightness == Brightness.dark ? Colors.green[300]! : Colors.green[700]!;
      } else if (score >= 40) {
        bgColor = Theme.of(context).brightness == Brightness.dark ? Colors.orange.withOpacity(0.2) : Colors.orange[50]!;
        textColor = Theme.of(context).brightness == Brightness.dark ? Colors.orange[300]! : Colors.orange[700]!;
      }
    }
    return GestureDetector(
      onTap: () {
        if (score != null) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.secondary),
                  const SizedBox(width: 8),
                  const Text('AI Match Analysis'),
                ],
              ),
              content: Text(explanation ?? 'No detailed analysis available at this time.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 12, color: AppTheme.getAdaptivePrimary(context)),
            const SizedBox(width: 4),
            Text(score != null ? '$score% Match' : '-% Match',
                style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
            if (explanation != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.info_outline, size: 12, color: textColor.withOpacity(0.6)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.getAdaptiveBackground(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'AI Matching...',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppTheme.getAdaptiveTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}
