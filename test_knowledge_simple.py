#!/usr/bin/env python3
"""
Simple test to verify knowledge retrieval is working
"""

import requests
import json

def test_simple_queries():
    api_url = "https://gentler-coparent-simple-rag.vercel.app/api/enhanced-chat"
    
    test_queries = [
        "coparenting communication",
        "custody",
        "visitation",
        "child support", 
        "Texas family law",
        "divorce"
    ]
    
    print("🧪 Testing simple knowledge retrieval...")
    
    for query in test_queries:
        print(f"\n📝 Query: '{query}'")
        
        try:
            response = requests.post(
                api_url,
                json={"message": query},
                headers={'Content-Type': 'application/json'},
                timeout=30
            )
            
            if response.status_code == 200:
                result = response.json()
                knowledge_used = result.get('knowledgeUsed', [])
                confidence = result.get('confidenceScore', 0)
                similarity_scores = result.get('similarityScores', [])
                
                print(f"   ✅ Status: Success")
                print(f"   📚 Knowledge sources: {len(knowledge_used)}")
                print(f"   🎯 Confidence: {confidence:.3f}")
                if similarity_scores:
                    print(f"   📊 Best similarity: {max(similarity_scores):.3f}")
                if knowledge_used:
                    print(f"   📄 First source: {knowledge_used[0]}")
                    
            else:
                print(f"   ❌ HTTP {response.status_code}: {response.text[:100]}...")
                
        except Exception as e:
            print(f"   ❌ Error: {e}")

if __name__ == "__main__":
    test_simple_queries()