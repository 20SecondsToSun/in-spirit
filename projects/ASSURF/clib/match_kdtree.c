//#include "kdtree/kdtree.h"

VlKDForest * refTree;

int getMatchesByTree(RefObject *obj, IPoint *currP, IPoint *refP, const int num1, const int num2, IPointMatch *matches, int prevMatchedCount, const double point_match_factor)
{
	int i, matchedCount = prevMatchedCount;
	
	double pmap[obj->pointsCount];
	int imap[obj->pointsCount];
	
	for(i=0; i<obj->pointsCount; i++)
	{
		pmap[i] = 1000000;
		imap[i] = -1;
	}
	for(i=0; i<prevMatchedCount; i++)
	{
		pmap[ matches[i].second->localIndex ] = matches[i].confidence;
		imap[ matches[i].second->localIndex ] = i;
	}
	
	VlKDForestNeighbor neighbors[2];
	
	refTree = obj->kdf;
	
	for(i = 0; i < num1; i++)
	{
		IPoint *curr = &currP[i];
		
		vl_kdforest_query (refTree, &*neighbors, 2, curr->descriptor);
		
		const double ratio = neighbors[0].distance / neighbors[1].distance;
		const int match_idx = neighbors[0].index;
		const double curr_dist = neighbors[0].distance;
		
		if(ratio < point_match_factor && pmap[match_idx] > curr_dist)
		{
			
			if(imap[match_idx] > -1)
			{
				IPointMatch *match = &matches[ imap[match_idx] ];
				
				match->first = curr;
				match->second = &obj->points[match_idx];
				match->confidence = curr_dist;
			}
			else
			{
				IPointMatch *match = &matches[matchedCount];
				
				match->first = curr;
				match->second = &obj->points[match_idx];
				match->confidence = curr_dist;
				
				imap[match_idx] = matchedCount;
				
				matchedCount++;
			}
			
			pmap[match_idx] = curr_dist;
		}
	}
	
	double max_dist = 0.0;
	for(i = 0; i < matchedCount; i++) 
	{
		if(max_dist < matches[i].confidence) 
		{
			max_dist = matches[i].confidence;
		}
	}
	for(i = 0; i < matchedCount; i++)
	{
		matches[i].normConfidence = matches[i].confidence / max_dist;
	}
	
	return matchedCount;
}

int getMatchesByMultiTree(IPoint *currP, IPoint *refP, const int num1, const int num2, IPointMatch *matches, int prevMatchedCount, const double point_match_factor)
{
	int i, matchedCount = prevMatchedCount;
	
	VlKDForestNeighbor neighbors[2];
	
	int t;
	
	for(t = 0; t < referenceCount; t++)
	{
		RefObject *obj = &refObjectsMap[t];
		refTree = obj->kdf;
		
		double pmap[obj->pointsCount];
		int imap[obj->pointsCount];
		
		obj->prevMatchedPointsCount = obj->matchedPointsCount;
		obj->matchedPointsCount = 0;
		
		for(i=0; i<obj->pointsCount; i++)
		{
			pmap[i] = 1000000;
			imap[i] = -1;
		}
		for(i=0; i<prevMatchedCount; i++)
		{
			if(obj->index == matches[i].second->refIndex)
			{
				IPointMatch *pfm = &matches[i];
				pmap[ pfm->second->localIndex ] = pfm->confidence;
				imap[ pfm->second->localIndex ] = obj->matchedPointsCount;
				memcpy(obj->matches + obj->matchedPointsCount, pfm, sizeof(IPointMatch));
				obj->matchedPointsCount++;
			}
		}
	
		for(i = 0; i < num1; i++)
		{			
			IPoint *curr = &currP[i];
			
			vl_kdforest_query (refTree, &*neighbors, 2, curr->descriptor);
			
			const double ratio = neighbors[0].distance / neighbors[1].distance;
			const int match_idx = neighbors[0].index;
			const double curr_dist = neighbors[0].distance;
			
			if(ratio < point_match_factor && pmap[match_idx] > curr_dist)
			{
				
				if(imap[match_idx] > -1)
				{
					IPointMatch *match = &obj->matches[ imap[match_idx] ];
					
					match->first = curr;
					match->second = &obj->points[match_idx];
					match->confidence = curr_dist;
				}
				else
				{
					IPointMatch *match = &obj->matches[obj->matchedPointsCount];
					
					match->first = curr;
					match->second = &obj->points[match_idx];
					match->confidence = curr_dist;
					
					imap[match_idx] = obj->matchedPointsCount;
					
					obj->matchedPointsCount++;
					matchedCount++;
				}
				
				pmap[match_idx] = curr_dist;
			}
		}
		
		if(obj->matchedPointsCount > 4)
		{
			double max_dist = 0.0;
			for(i = 0; i < obj->matchedPointsCount; i++) 
			{
				if(max_dist < obj->matches[i].confidence) 
				{
					max_dist = obj->matches[i].confidence;
				}
			}
			for(i = 0; i < obj->matchedPointsCount; i++)
			{
				obj->matches[i].normConfidence = obj->matches[i].confidence / max_dist;
			}
		}
	}
	
	return matchedCount;
}
