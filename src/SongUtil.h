/** @brief SongUtil - Utility functions that deal with Song. */

#ifndef SONG_UTIL_H
#define SONG_UTIL_H

#include "Difficulty.h"
#include "GameConstantsAndTypes.h"
#include "RageUtil_CachedObject.h"
#include <set>

class Song;
class Steps;
class Profile;
class XNode;

void
AppendOctal(int n, int digits, RString& out);

/** @brief A set of song utilities to make working with songs easier. */
namespace SongUtil {
void
GetSteps(const Song* pSong,
		 vector<Steps*>& arrayAddTo,
		 StepsType st = StepsType_Invalid,
		 Difficulty dc = Difficulty_Invalid,
		 int iMeterLow = -1,
		 int iMeterHigh = -1,
		 const RString& sDescription = "",
		 const RString& sCredit = "",
		 bool bIncludeAutoGen = true,
		 unsigned uHash = 0,
		 int iMaxToGet = -1);
Steps*
GetOneSteps(const Song* pSong,
			StepsType st = StepsType_Invalid,
			Difficulty dc = Difficulty_Invalid,
			int iMeterLow = -1,
			int iMeterHigh = -1,
			const RString& sDescription = "",
			const RString& sCredit = "",
			unsigned uHash = 0,
			bool bIncludeAutoGen = true);
Steps*
GetStepsByDifficulty(const Song* pSong,
					 StepsType st,
					 Difficulty dc,
					 bool bIncludeAutoGen = true);
Steps*
GetStepsByMeter(const Song* pSong, StepsType st, int iMeterLow, int iMeterHigh);
Steps*
GetStepsByDescription(const Song* pSong,
					  StepsType st,
					  const RString& sDescription);
Steps*
GetStepsByCredit(const Song* pSong, StepsType st, const RString& sCredit);
Steps*
GetClosestNotes(const Song* pSong,
				StepsType st,
				Difficulty dc,
				bool bIgnoreLocked = false);

void
AdjustDuplicateSteps(Song* pSong); // part of TidyUpData
void
DeleteDuplicateSteps(Song* pSong, vector<Steps*>& vSteps);

void
MakeSortString(RString& s);
RString
MakeSortString(const string& in);
void
SortSongPointerArrayByTitle(vector<Song*>& vpSongsInOut);
void
SortSongPointerArrayByBPM(vector<Song*>& vpSongsInOut);
void
SortSongPointerArrayByGrades(vector<Song*>& vpSongsInOut, bool bDescending);
void
SortSongPointerArrayByArtist(vector<Song*>& vpSongsInOut);
void
SortSongPointerArrayByDisplayArtist(vector<Song*>& vpSongsInOut);
void
SortSongPointerArrayByGenre(vector<Song*>& vpSongsInOut);
void
SortSongPointerArrayByGroupAndTitle(vector<Song*>& vpSongsInOut);
void
SortSongPointerArrayByGroupAndMSD(vector<Song*>& vpSongsInOut, Skillset ss);
void
SortSongPointerArrayByNumPlays(vector<Song*>& vpSongsInOut,
							   ProfileSlot slot,
							   bool bDescending);
void
SortSongPointerArrayByNumPlays(vector<Song*>& vpSongsInOut,
							   const Profile* pProfile,
							   bool bDescending);
void
SortSongPointerArrayByStepsTypeAndMeter(vector<Song*>& vpSongsInOut,
										StepsType st,
										Difficulty dc);
RString
GetSectionNameFromSongAndSort(const Song* pSong, SortOrder so);
void
SortSongPointerArrayBySectionName(vector<Song*>& vpSongsInOut, SortOrder so);
void
SortSongPointerArrayByLength(vector<Song*>& vpSongsInOut);

int
CompareSongPointersByGroup(const Song* pSong1, const Song* pSong2);

/**
 * @brief Determine if the requested description for an edit is unique.
 * @param pSong the song the edit is for.
 * @param st the steps type for the edit.
 * @param sPreferredDescription the requested description.
 * @param pExclude the steps that want the description.
 * @return true if it is unique, false otherwise.
 */
bool
IsEditDescriptionUnique(const Song* pSong,
						StepsType st,
						const RString& sPreferredDescription,
						const Steps* pExclude);
bool
IsChartNameUnique(const Song* pSong,
				  StepsType st,
				  const RString& name,
				  const Steps* pExclude);
RString
MakeUniqueEditDescription(const Song* pSong,
						  StepsType st,
						  const RString& sPreferredDescription);
bool
ValidateCurrentEditStepsDescription(const RString& sAnswer, RString& sErrorOut);
bool
ValidateCurrentStepsDescription(const RString& sAnswer, RString& sErrorOut);
bool
ValidateCurrentStepsCredit(const RString& sAnswer, RString& sErrorOut);
bool
ValidateCurrentStepsChartName(const RString& answer, RString& error);
bool
ValidateCurrentSongPreview(const RString& answer, RString& error);
bool
ValidateCurrentStepsMusic(const RString& answer, RString& error);

void
GetAllSongGenres(vector<RString>& vsOut);
void
GetPlayableStepsTypes(const Song* pSong, set<StepsType>& vOut);
void
GetPlayableSteps(const Song* pSong, vector<Steps*>& vOut);
bool
IsStepsTypePlayable(Song* pSong, StepsType st);
bool
IsStepsPlayable(Song* pSong, Steps* pSteps);

/**
 * @brief Determine if the song has any playable steps in the present game.
 * @param s the current song.
 * @return true if the song has playable steps, false otherwise. */
bool
IsSongPlayable(Song* s);

bool
GetStepsTypeAndDifficultyFromSortOrder(SortOrder so,
									   StepsType& st,
									   Difficulty& dc);
}

class SongID
{
	RString sDir;
	mutable CachedObjectPointer<Song> m_Cache;

  public:
	/**
	 * @brief Set up the SongID with default values.
	 *
	 * This used to call Unset() to do the same thing. */
	SongID()
	  : sDir("")
	  , m_Cache()
	{
		m_Cache.Unset();
	}
	void Unset() { FromSong(nullptr); }
	void FromSong(const Song* p);
	Song* ToSong() const;
	bool operator<(const SongID& other) const { return sDir < other.sDir; }
	bool operator==(const SongID& other) const { return sDir == other.sDir; }

	XNode* CreateNode() const;
	void LoadFromNode(const XNode* pNode);
	void LoadFromString(const char* dir);
	void FromString(RString _sDir) { sDir = _sDir; }
	RString ToString() const;
	bool IsValid() const;
};

#endif

/**
 * @file
 * @author Chris Danford, Glenn Maynard (c) 2001-2004
 * @section LICENSE
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, and/or sell copies of the Software, and to permit persons to
 * whom the Software is furnished to do so, provided that the above
 * copyright notice(s) and this permission notice appear in all copies of
 * the Software and that both the above copyright notice(s) and this
 * permission notice appear in supporting documentation.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF
 * THIRD PARTY RIGHTS. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR HOLDERS
 * INCLUDED IN THIS NOTICE BE LIABLE FOR ANY CLAIM, OR ANY SPECIAL INDIRECT
 * OR CONSEQUENTIAL DAMAGES, OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
 * OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
 * OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 */
