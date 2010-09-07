#include "kdtree/kdtree.h"

VlKDForest * refTree;

void buildRefIndexTree(double *descriptorsRef, const int referencePointsCount, const int dimension)
{
	if(refTree) vl_kdforest_delete(refTree);
	
	refTree = vl_kdforest_new ( dimension, 5 );
	vl_kdforest_build (refTree, referencePointsCount, descriptorsRef);
	vl_kdforest_set_max_num_comparisons(refTree, 81);
}

int getMatchesByTree(IPoint *currP, IPoint *refP, const int num1, const int num2, IPointMatch *matches, int prevMatchedCount, const double point_match_factor)
{
	int i, matchedCount = prevMatchedCount;
	
	double pmap[num2];
	int imap[num2];
	
	for(i=0; i<num2; i++)
	{
		if(i < prevMatchedCount)
		{
			pmap[i] = matches[i].confidence;//(double)1.0 - matches[i].confidence;
			imap[ matches[i].second->index ] = i;
		} else 
		{
			pmap[i] = 1000000;//point_match_factor;
			imap[i] = -1;
		}
	}
	
	VlKDForestNeighbor neighbors[2];
	
	for(i = 0; i < num1; i++)
	{
		IPoint *curr = &currP[i];
		
		vl_kdforest_query (refTree, &*neighbors, 2, curr->descriptor);
		
		const double ratio = neighbors[0].distance / neighbors[1].distance;
		const int match_idx = neighbors[0].index;
		
		if(ratio < point_match_factor && pmap[match_idx] > neighbors[0].distance)
		{
			
			if(imap[match_idx] > -1)
			{
				IPointMatch *match = &matches[ imap[match_idx] ];
				
				match->first = curr;
				match->second = &refP[match_idx];
				match->confidence = neighbors[0].distance;//(double)1.0 - ratio;
			}
			else
			{
				IPointMatch *match = &matches[matchedCount];
				
				match->first = curr;
				match->second = &refP[match_idx];
				match->confidence = neighbors[0].distance;//(double)1.0 - ratio;
				
				imap[match_idx] = matchedCount;
				
				matchedCount++;
			}
			
			pmap[match_idx] = neighbors[0].distance;//ratio;
		}
	}
	
	return matchedCount;
}